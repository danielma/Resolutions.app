//
//  Database.swift
//  BestOf
//
//  Created by Daniel Ma on 11/5/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import GRDB

// The shared database queue.
var dbQueue: DatabaseQueue!

func setupDatabase() throws {
  var config = Configuration()
  config.foreignKeysEnabled = true
  config.trace = { print($0) }
  // Connect to the database
  // See https://github.com/groue/GRDB.swift/#database-connections

  let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
  let path = try! FileManager().url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
  let appPath = path.appendingPathComponent(appName)
  try! FileManager().createDirectory(at: appPath, withIntermediateDirectories: true, attributes: nil)
  let dbPath = appPath.appendingPathComponent("db.sqlite")

  print(dbPath.absoluteString)
  dbQueue = try DatabaseQueue(path: dbPath.absoluteString, configuration: config)


  // Use DatabaseMigrator to setup the database
  // See https://github.com/groue/GRDB.swift/#migrations

  var migrator = DatabaseMigrator()

  migrator.registerMigration("CreateResolutionsTable") { db in
    try db.create(table: "resolutions") { t in
      t.column("id", .integer).primaryKey()
      t.column("remoteIdentifier", .text).notNull().unique()
      t.column("name", .text).notNull()
      t.column("completedAt", .date)

      t.column("createdAt", .date).notNull()
      t.column("updatedAt", .date).notNull()
    }
  }

  try migrator.migrate(dbQueue)
}

