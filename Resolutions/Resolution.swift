//
//  Resolution.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/19/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Foundation
import GRDB

class Resolution: AppRecord {
  override class var databaseTableName: String { return "resolutions" }

  var completedAt: Date?
  var remoteIdentifier: String
  var name: String

  required init(row: Row) {
    completedAt = row.value(named: "completedAt")
    remoteIdentifier = row.value(named: "remoteIdentifier")
    name = row.value(named: "name")

    super.init(row: row)
  }

  init(name: String, remoteIdentifier: String, completedAt: Date?) {
    self.name = name
    self.remoteIdentifier = remoteIdentifier
    self.completedAt = completedAt
    super.init()
  }

  var completed: Bool {
    if let completedAt = completedAt {
      return completedAt <= Date()
    }

    return false
  }

  convenience init(name: String, remoteIdentifier: String) {
    self.init(name: name, remoteIdentifier: remoteIdentifier, completedAt: nil)
  }

  override var appRecordDictionary: [String : DatabaseValueConvertible?] {
    return [
      "completedAt": completedAt,
      "remoteIdentifier": remoteIdentifier,
      "name": name,
    ]
  }
}
