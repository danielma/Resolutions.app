//
//  GithubPoller.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/20/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Foundation
import SwiftyJSON
import GRDB

func jsonDateToDate(_ jsonDate: String?) -> Date? {
  guard let jsonDate = jsonDate else { return nil }

  let dateFormatter = DateFormatter()
  dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
  return dateFormatter.date(from: jsonDate)
}

class GithubPoller {
  let notificationsPoller: RequestPoller
  let eventsPoller: RequestPoller
  let userDefaults: UserDefaults

  static let ignoredEventsKey = "githubIgnoredEvents"
  static let ignoredEventsDefaultValue = Dictionary<String,Bool>()
  static let ignorableEvents = [
    ("pullRequestMerged", "When a Pull Request is merged"),
  ]

  static let forcedUpdateNotificationName = NSNotification.Name("githubPollerForceUpdate")

  static let sharedInstance = GithubPoller(defaults: UserDefaults.standard)

  init(defaults: UserDefaults) {
    userDefaults = defaults
    notificationsPoller = GithubAPIClient.sharedInstance.pollNotifications()
    eventsPoller = GithubAPIClient.sharedInstance.pollUserEvents()

    notificationsPoller
      .map { notifications in
        notifications.arrayValue.reversed().forEach { self.handleNotification($0) }
      }

    eventsPoller
      .map { events in
        events.arrayValue.reversed().forEach { self.handleEvent($0) }
      }
  }

  func start() {
    notificationsPoller.start()
    eventsPoller.start()
  }

  func forceUpdate() {
    notificationsPoller.forceRequest()
    eventsPoller.forceRequest()

    NotificationCenter.default.post(name: GithubPoller.forcedUpdateNotificationName, object: self)
  }

  deinit {
    notificationsPoller.stop()
    eventsPoller.stop()
  }

  internal func handleNotification(_ notification: JSON) {
    let incomingResolution = Resolution(fromGithubNotification: notification)

    dbQueue.inDatabase { db in
      var resolution = try! Resolution
        .filter(Column("remoteIdentifier") == incomingResolution.remoteIdentifier)
        .fetchOne(db)

      let updatedAt = jsonDateToDate(notification["updated_at"].string)

      if let resolution = resolution {
        if let updatedAt = updatedAt, resolution.updatedAt! < updatedAt {
          resolution.completedAt = nil
        }
      } else {
        resolution = incomingResolution
        resolution!.createdAt = updatedAt
      }

      if let updatedAt = updatedAt {
        resolution?.updatedAt = updatedAt
      }
      
      if resolution!.hasPersistentChangedValues {
        try! resolution!.save(db)
      }
    }
  }

  internal func handleEvent(_ event: JSON) {
    let lastEventReadId = userDefaults.value(forKey: "githubLastEventReadId") as! Int

    guard let eventId = Int(event["id"].stringValue) else { return }
    guard eventId > lastEventReadId else { return }
    guard let kind = GithubUserEvent.Kind(rawValue: event["type"].stringValue) else { return }
    guard shouldIgnoreEvent(event) == false else { return }

    switch kind {
    case .IssueCommentEvent:
      handleIssueCommentEvent(event)
    case .PullRequestReviewCommentEvent:
      handlePullRequestReviewCommentEvent(event)
    case .PullRequestEvent:
      handlePullRequestEvent(event)
    }
    
    UserDefaults.standard.set(eventId, forKey: "githubLastEventReadId")
  }

  internal func shouldIgnoreEvent(_ event: JSON) -> Bool {
    return false
  }

  internal func handleIssueCommentEvent(_ event: JSON) {
    let payload = event["payload"]
    let issueIdentifier = payload["issue", "url"].stringValue
    let event = GithubUserEvent(event: event, issueIdentifier: issueIdentifier)

    guard event.isValid else { return }
    if userDefaults.bool(forKey: "githubUseMagicComments") {
      let magicValue = userDefaults.string(forKey: "githubMagicCommentString")
      guard !event.commentIncludesMagicValue(magicValue) else { return }
    }

    event.resolution?.completedAt = event.createdAt
    dbQueue.inDatabase { db in
      try! event.resolution?.save(db)
    }
  }

  internal func handlePullRequestReviewCommentEvent(_ event: JSON) {
    let payload = event["payload"]
    let issueIdentifier = payload["pull_request", "issue_url"].stringValue
    let event = GithubUserEvent(event: event, issueIdentifier: issueIdentifier)

    guard event.isValid else { return }
    if userDefaults.bool(forKey: "githubUseMagicComments") {
      let magicValue = userDefaults.string(forKey: "githubMagicCommentString")
      guard !event.commentIncludesMagicValue(magicValue) else { return }
    }

    event.resolution?.completedAt = event.createdAt
    dbQueue.inDatabase { db in
      try! event.resolution?.save(db)
    }
  }

  internal func handlePullRequestEvent(_ event: JSON) {
    let payload = event["payload"]
    let issueIdentifier = payload["pull_request", "issue_url"].stringValue
    let event = GithubUserEvent(event: event, issueIdentifier: issueIdentifier)

    guard event.isValid, let resolution = event.resolution
      else { return }

    if payload["action"].stringValue == "closed" {
      resolution.completedAt = event.createdAt
    }

    if resolution.hasPersistentChangedValues {
      dbQueue.inDatabase { db in
        try! resolution.save(db)
      }
    }
  }
}

class GithubUserEvent {
  enum Kind: String {
    case IssueCommentEvent
    case PullRequestReviewCommentEvent
    case PullRequestEvent
  }

  var resolution: Resolution? = nil
  let createdAt: Date
  let event: JSON

  init(event: JSON, issueIdentifier: String) {
    self.event = event
    createdAt = jsonDateToDate(event["created_at"].stringValue)!

    dbQueue.inDatabase { db in
      resolution = try! Resolution.filter(Column("remoteIdentifier") == issueIdentifier).fetchOne(db)
    }
  }

  func commentIncludesMagicValue(_ magicValue: String?) -> Bool {
    guard let magicValue = magicValue else { return false }

    let comment = event["payload", "comment"]

    guard comment.exists() else { return false }

    return comment["body"].stringValue.contains(magicValue)
  }

  var isValid: Bool {
    if let resolution = resolution {
      return !resolution.completed && resolution.updatedAt! < createdAt
    }

    return false
  }
}
