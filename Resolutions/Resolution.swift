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
    remoteIdentifier = row.value(named: "removeIdentifier")
    name = row.value(named: "row")

    super.init(row: row)
  }

  override var appRecordDictionary: [String : DatabaseValueConvertible?] {
    return [
      "completedAt": completedAt,
      "remoteIdentifier": remoteIdentifier,
      "name": name,
    ]
  }
}
