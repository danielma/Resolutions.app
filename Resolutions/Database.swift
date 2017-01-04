//
//  Database.swift
//  BestOf
//
//  Created by Daniel Ma on 11/5/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import GRDB

// The shared database queue.
fileprivate var databaseSetup = false
fileprivate var _dbQueue: DatabaseQueue!
var dbQueue: DatabaseQueue {
  if !databaseSetup { try! setupDatabase() }
  return _dbQueue
}

let isTestMode = ProcessInfo.processInfo.environment["TESTING"] != nil

var appPath: URL = {
  var appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String
  if isTestMode {
    appName += "testMode"
  }
  let path = try! FileManager().url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

  return path.appendingPathComponent(appName)
}()

var dbPath: URL = {
  return appPath.appendingPathComponent("db.sqlite")
}()

fileprivate func ensureDbFileExists() {
  try! FileManager.default.createDirectory(at: appPath, withIntermediateDirectories: true, attributes: nil)
}

func setupDatabase() throws {
  var config = Configuration()
  config.foreignKeysEnabled = true
//  config.trace = { print($0) }
  // Connect to the database
  // See https://github.com/groue/GRDB.swift/#database-connections

  ensureDbFileExists()

  _dbQueue = try DatabaseQueue(path: dbPath.absoluteString, configuration: config)

  // Use DatabaseMigrator to setup the database
  // See https://github.com/groue/GRDB.swift/#migrations

  var migrator = DatabaseMigrator()

  migrator.registerMigration("CreateResolutionsTable") { db in
    try db.create(table: "resolutions") { t in
      t.column("id", .integer).primaryKey()
      t.column("remoteIdentifier", .text).notNull().unique()
      t.column("name", .text).notNull()
      t.column("grouping", .text)
      t.column("completedAt", .date)

      t.column("createdAt", .date).notNull()
      t.column("updatedAt", .date).notNull()
    }
  }

  try migrator.migrate(_dbQueue!)

  databaseSetup = true
}

func deleteDatabase() throws {
  try! FileManager.default.removeItem(at: dbPath)
  databaseSetup = false
}
