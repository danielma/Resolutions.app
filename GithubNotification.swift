//
//  GithubNotification.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/3/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import SwiftyJSON
import PromiseKit

class GithubNotification {
  let source: JSON

  init(_ source: JSON) {
    self.source = source
  }

  lazy var id: Int = {
    return Int(self.source["id"].stringValue)!
  }()

  lazy var reason: NotificationReason = {
    return NotificationReason(rawValue: self.source["reason"].stringValue)!
  }()

  lazy var updatedAt: Date = {
    return jsonDateToDate(self.source["updated_at"].string)!
  }()

  lazy var subject: Promise<GithubNotificationSubject> = {
    return Promise(value: GithubNotificationSubject())
  }()

  enum NotificationReason: String {
    case assign
    case author
    case comment
    case invitation
    case manual
    case mention
    case stateChange = "state_change"
    case subscribed
    case teamMention = "team_mention"
  }
}

class GithubNotificationSubject {}
