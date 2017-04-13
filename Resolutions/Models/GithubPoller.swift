//
//  GithubPoller.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/20/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Cocoa
import SwiftyJSON
import PromiseKit

class GithubPoller {
  let eventsPoller: GithubRequestPoller<GithubEvent>
  let notificationsPoller: GithubRequestPoller<GithubNotification>
  let userDefaults: UserDefaults
  lazy var appDelegate: AppDelegate = {
    return NSApplication.shared().delegate as! AppDelegate
  }()
  lazy var managedObjectContext: NSManagedObjectContext = {
    let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    context.parent = self.appDelegate.managedObjectContext
    return context
  }()

  static let updateStartedNotificationName = NSNotification.Name("githubPollerUpdateStarted")
  static let updateFinishedNotificationName = NSNotification.Name("githubPollerUpdateFinished")
  
  static let lastEventKey = "githubLastEventReadId"
  static let sharedInstance = GithubPoller(defaults: UserDefaults.standard)
  static let queue = DispatchQueue(label: "com.resolutions.githubPollerQueue")

  init(defaults: UserDefaults) {
    userDefaults = defaults

    eventsPoller = GithubRequestPoller { lastData in
      let usefulSince: Int?

      if let lastData = lastData {
        usefulSince = lastData.last?.id ?? nil
      } else {
        usefulSince = defaults.value(forKey: GithubPoller.lastEventKey) as? Int
      }

      return GithubAPIClient.sharedInstance.allUserEvents(since: usefulSince)
    }

    notificationsPoller = GithubRequestPoller { _ in
      if let lastAccessed = GithubAPIClient.sharedInstance.notificationsLastAccessedDate {
        debugPrint("notifications if modified since \(lastAccessed)")
        return GithubAPIClient.sharedInstance.allNotifications(headers: ["If-Modified-Since": lastAccessed])
      }
      
      return GithubAPIClient.sharedInstance.allNotifications()
    }

    eventsPoller
      .map { events in
        NotificationCenter.default.post(name: GithubPoller.updateStartedNotificationName, object: self)
        GithubPoller.queue.sync {
          events.forEach { self.handleEvent($0) }
          do {
            NotificationCenter.default.post(name: GithubPoller.updateFinishedNotificationName, object: self)
            try self.managedObjectContext.save()
          } catch let error {
            debugPrint(error)
          }
        }
    }

    notificationsPoller
      .map { notifications in
        NotificationCenter.default.post(name: GithubPoller.updateStartedNotificationName, object: self)
        GithubPoller.queue.sync {
          when(resolved: notifications.map { self.handleNotification($0) })
            .always {
              NotificationCenter.default.post(name: GithubPoller.updateFinishedNotificationName, object: self)
              do {
                try self.managedObjectContext.save()
              } catch let error {
                debugPrint(error)
              }
          }
        }
    }
  }

  func start() {
    notificationsPoller.start()
    eventsPoller.start()
  }

  func forceUpdate() {
    notificationsPoller.forceRequest()
    eventsPoller.forceRequest()

    NotificationCenter.default.post(name: GithubPoller.updateStartedNotificationName, object: self)
  }

  deinit {
    eventsPoller.stop()
    notificationsPoller.stop()
//    receivedEventsPoller.stop()
  }

  internal func handleEvent(_ event: GithubEvent) {
    debugPrint("received event \(event.id): \(event.eventType)")

    event.updateResolution(context: managedObjectContext)

    userDefaults.set(event.id, forKey: GithubPoller.lastEventKey)
  }

  internal func handleNotification(_ notification: GithubNotification) -> Promise<Void> {
    debugPrint("received notification \(notification.id): \(notification.type)")

    let promise = notification.updateResolution(context: managedObjectContext)

    if let promise = promise {
      return promise.asVoid()
    } else {
      return Promise(value: Void())
    }
  }
}
