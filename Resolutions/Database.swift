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

  let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as NSString
  let dbPath = documentsPath.appendingPathComponent("db.sqlite")
  dbQueue = try DatabaseQueue(path: dbPath, configuration: config)


  // Use DatabaseMigrator to setup the database
  // See https://github.com/groue/GRDB.swift/#migrations

  var migrator = DatabaseMigrator()

  migrator.registerMigration("CreateResolutionsTable") { db in
    try db.create(table: "resolutions") { t in
      t.column("id", .integer).primaryKey()
      t.column("remoteIdentifier", .text).notNull()
      t.column("name", .text).notNull()
      t.column("completedAt", .date)

      t.column("createdAt", .date).notNull()
      t.column("updatedAt", .date).notNull()
    }
  }

//  migrator.registerMigration("CreateConfigurationTable") { db in
//    try db.create(table: "appConfiguration") { t in
//      t.column("key", .text).primaryKey()
//      t.column("createdAt", .date).notNull()
//      t.column("updatedAt", .date).notNull()
//      t.column("value", .text).notNull()
//    }
//
//    let githubTokenConfiguration = AppConfiguration.filter(Column("key") == "githubToken").fetchOne(db)
//
//    if githubTokenConfiguration === nil {
//      let newGithubTokenConfiguration = AppConfiguration(key: "githubToken", value: "")
//
//      try! newGithubTokenConfiguration.save(db)
//    }
//  }

  try migrator.migrate(dbQueue)
}

