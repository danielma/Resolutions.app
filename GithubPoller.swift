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
  let eventsPoller: GithubRequestPoller
  let userDefaults: UserDefaults
  lazy var managedObjectContext: NSManagedObjectContext = {
    return (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
  }()

  static let forcedUpdateNotificationName = NSNotification.Name("githubPollerForceUpdate")
  static let sharedInstance = GithubPoller(defaults: UserDefaults.standard)

  init(defaults: UserDefaults) {
    userDefaults = defaults
    eventsPoller = GithubAPIClient.sharedInstance.pollUserEvents(since: userDefaults.value(forKey: "githubLastEventReadId") as? Int)

    eventsPoller
      .map { events in
        DispatchQueue.global().async {
          events.forEach { self.handleEvent($0) }
        }
      }
  }

  func start() {
    eventsPoller.start()
  }

  func forceUpdate() {
    eventsPoller.forceRequest()

    NotificationCenter.default.post(name: GithubPoller.forcedUpdateNotificationName, object: self)
  }

  deinit {
    eventsPoller.stop()
  }

  internal func handleNotification(_ notification: JSON) {
    let resolution = ResolutionMO.fromGithubNotification(notification, context: managedObjectContext)
    let updatedAt = jsonDateToDate(notification["updated_at"].string)!

    if let updateDate = resolution.updateDate,
      updateDate.compare(updatedAt) == .orderedAscending {
      resolution.completedDate = nil
    }

    resolution.updateDate = updatedAt as NSDate
  }

  internal func handleEvent(_ event: GithubEvent) {
    debugPrint("received event \(event.id): \(event.eventType)")

    switch event.eventType {
    case .IssueCommentEvent:
      handleIssueCommentEvent(event)
    case .PullRequestReviewCommentEvent:
      handlePullRequestReviewCommentEvent(event)
    case .PullRequestEvent:
      handlePullRequestEvent(event)
    default:
      debugPrint("unhandled event: \(event.eventType)")
    }
    
    userDefaults.set(event.id, forKey: "githubLastEventReadId")
  }

  internal func handleIssueCommentEvent(_ event: GithubEvent) {
   guard event.afterResolutionUpdatedAt, let resolution = event.resolution else { return }
//   if userDefaults.bool(forKey: "githubUseMagicComments") {
//     let magicValue = userDefaults.string(forKey: "githubMagicCommentString")
//     guard !event.commentIncludesMagicValue(magicValue) else { return }
//   }

   resolution.completedDate = event.createdAt as NSDate
  }

  internal func handlePullRequestReviewCommentEvent(_ event: GithubEvent) {
      guard event.afterResolutionUpdatedAt, let resolution = event.resolution else { return }
//      if userDefaults.bool(forKey: "githubUseMagicComments") {
//          let magicValue = userDefaults.string(forKey: "githubMagicCommentString")
//          guard !event.commentIncludesMagicValue(magicValue) else { return }
//      }

      resolution.completedDate = event.createdAt as NSDate
  }

  internal func handlePullRequestEvent(_ event: GithubEvent) {
    guard event.afterResolutionUpdatedAt, let resolution = event.resolution else { return }
    
    let prEvent = GithubPullRequestEvent(event.source)

    if prEvent.action == .closed {
      resolution.completedDate = event.createdAt as NSDate
    }
  }
}
