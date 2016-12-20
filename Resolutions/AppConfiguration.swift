//
//  AppConfiguration.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/19/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Foundation
import GRDB

class AppConfiguration: AppRecord {
  override class var databaseTableName: String { return "appConfiguration" }

  var key: String
  var value: String

  
}
