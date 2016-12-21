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
            notifications.arrayValue.forEach { self.handleNotification(db, $0) }

            return .commit
          }
        }
      }
      .start()

    eventsPoller
      .map { events in
        DispatchQueue.global().async {
          try! dbQueue.inTransaction { db in
            events.arrayValue.forEach { self.handleEvent(db, $0) }

            return .commit
          }
        }
      }
      .start()
  }

  func forceUpdate() {
    notificationsPoller.forceRequest()
    eventsPoller.forceRequest()
  }

  deinit {
    notificationsPoller.stop()
    eventsPoller.stop()
  }

  internal func handleNotification(_ db: Database, _ notification: JSON) {
    var resolution = try! Resolution
      .filter(Column("remoteIdentifier") == notification["subject", "url"].stringValue)
      .fetchOne(db)
    
    if let resolution = resolution {
      if let updatedAt = jsonDateToDate(notification["updated_at"].string), resolution.updatedAt! < updatedAt {
        resolution.completedAt = nil
      }
    } else {
      let resolutionName = notification["subject", "title"].stringValue
      let remoteIdentifier = notification["subject", "url"].stringValue
      resolution = Resolution(
        name: resolutionName,
        remoteIdentifier: remoteIdentifier
      )
    }
    
    if resolution!.hasPersistentChangedValues {
      print("Adding resolution", resolution!)
      try! resolution!.save(db)
    }
  }

  internal func handleEvent(_ db: Database, _ event: JSON) {
    debugPrint("event", event["id"].stringValue)
//    let lastEventRead =
  }
}
