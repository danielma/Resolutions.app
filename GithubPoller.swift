//
//  GithubPoller.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/20/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Cocoa
import SwiftyJSON

class GithubPoller {
  let eventsPoller: GithubRequestPoller<GithubEvent>
  let notificationsPoller: GithubRequestPoller<GithubNotification>
  let userDefaults: UserDefaults
  lazy var managedObjectContext: NSManagedObjectContext = {
    return (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
  }()

  static let forcedUpdateNotificationName = NSNotification.Name("githubPollerForceUpdate")
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

//    receivedEventsPoller = GithubRequestPoller { lastData in
//      let usefulSince: Int?
//
//      if let lastData = lastData {
//        usefulSince = lastData.last?.id ?? nil
//      } else {
//        usefulSince = defaults.value(forKey: GithubPoller.lastEventKey) as? Int
//      }
//
//      return GithubAPIClient.sharedInstance.allReceivedEvents(since: usefulSince)
//    }

    eventsPoller
      .map { events in
        GithubPoller.queue.sync {
          events.forEach { self.handleEvent($0) }
        }
    }

//    receivedEventsPoller
//      .map { events in
//        GithubPoller.queue.sync {
//          events.forEach { self.handleEvent($0) }
//        }
//    }

    notificationsPoller
      .map { notifications in
        notifications.forEach { debugPrint($0) }
    }
  }

  func start() {
    eventsPoller.start()
    notificationsPoller.start()
//    receivedEventsPoller.start()
  }

  func forceUpdate() {
    eventsPoller.forceRequest()
    notificationsPoller.forceRequest()
//    receivedEventsPoller.forceRequest()

    NotificationCenter.default.post(name: GithubPoller.forcedUpdateNotificationName, object: self)
  }

  deinit {
    eventsPoller.stop()
    notificationsPoller.stop()
//    receivedEventsPoller.stop()
  }

  internal func handleEvent(_ event: GithubEvent) {
    debugPrint("received event \(event.id): \(event.eventType)")

    event.updateResolution()
    
    userDefaults.set(event.id, forKey: GithubPoller.lastEventKey)
  }
}
