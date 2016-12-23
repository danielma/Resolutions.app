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

  static let forcedUpdateNotificationName = NSNotification.Name("githubPollerForceUpdate")

  static let sharedInstance = GithubPoller()
  
  init() {
    notificationsPoller = GithubAPIClient.sharedInstance.pollNotifications()
    eventsPoller = GithubAPIClient.sharedInstance.pollUserEvents()
  }

  func start() {
    notificationsPoller
      .map { notifications in
        DispatchQueue.global().async {
          try! dbQueue.inTransaction { db in
            notifications.arrayValue.reversed().forEach { self.handleNotification(db, $0) }

            return .commit
          }
        }
      }
      .start()

    eventsPoller
      .map { events in
        DispatchQueue.global().async {
          try! dbQueue.inTransaction { db in
            events.arrayValue.reversed().forEach { self.handleEvent(db, $0) }

            return .commit
          }
        }
      }
      .start()
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

  internal func handleNotification(_ db: Database, _ notification: JSON) {
    let incomingResolution = Resolution(fromGithubNotification: notification)

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

  internal func handleEvent(_ db: Database, _ event: JSON) {
    let lastEventReadId = UserDefaults.standard.value(forKey: "githubLastEventReadId") as! Int

    guard let eventId = Int(event["id"].stringValue) else { return }
    guard eventId > lastEventReadId else { return }
    guard let kind = GithubUserEvent.Kind(rawValue: event["type"].stringValue) else { return }

    switch kind {
    case .IssueCommentEvent:
      handleIssueCommentEvent(db, event)
    case .PullRequestReviewCommentEvent:
      handlePullRequestReviewCommentEvent(db, event)
    case .PullRequestEvent:
      handlePullRequestEvent(db, event)
    }
    
    UserDefaults.standard.set(eventId, forKey: "githubLastEventReadId")
  }

  internal func handleIssueCommentEvent(_ db: Database, _ event: JSON) {
    let payload = event["payload"]
    let issueIdentifier = payload["issue", "url"].stringValue

    guard
      let resolution = try! Resolution.filter(Column("remoteIdentifier") == issueIdentifier).fetchOne(db),
      !resolution.completed,
      let eventCreatedAt = jsonDateToDate(event["created_at"].stringValue),
      resolution.updatedAt! < eventCreatedAt
      else { return }

    resolution.completedAt = eventCreatedAt
    try! resolution.save(db)
  }

  internal func handlePullRequestReviewCommentEvent(_ db: Database, _ event: JSON) {
    let payload = event["payload"]
    let issueIdentifier = payload["pull_request", "issue_url"].stringValue

    guard
      let resolution = try! Resolution.filter(Column("remoteIdentifier") == issueIdentifier).fetchOne(db),
      !resolution.completed,
      let eventCreatedAt = jsonDateToDate(event["created_at"].stringValue),
      resolution.updatedAt! < eventCreatedAt
      else { return }

    resolution.completedAt = eventCreatedAt
    try! resolution.save(db)
  }

  internal func handlePullRequestEvent(_ db: Database, _ event: JSON) {
    let payload = event["payload"]
    let issueIdentifier = payload["pull_request", "issue_url"].stringValue

    guard
      let resolution = try! Resolution.filter(Column("remoteIdentifier") == issueIdentifier).fetchOne(db),
      !resolution.completed,
      let eventCreatedAt = jsonDateToDate(event["created_at"].stringValue),
      resolution.updatedAt! < eventCreatedAt
      else { return }

    if payload["action"].stringValue == "closed" {
      resolution.completedAt = eventCreatedAt
    }

    if resolution.hasPersistentChangedValues {
      try! resolution.save(db)
    }
  }
}

class GithubUserEvent {
  enum Kind: String {
    case IssueCommentEvent
    case PullRequestReviewCommentEvent
    case PullRequestEvent
  }
}
