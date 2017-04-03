//
//  UpdateListener.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/3/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//  Thanks to http://www.rugenheidbuchel.be/2015/08/03/core-data-update-listener-in-swift/
//

import CoreData

class UpdateListener {
  static var loggingEnabled = true

  var insertDateProperty = "insertDate"
  var updateDateProperty = "updateDate"

  static let sharedInstance = UpdateListener()

  func listen() {
    NotificationCenter.default.addObserver(self, selector: #selector(willSave(notification:)), name: NSNotification.Name.NSManagedObjectContextWillSave, object: nil)
  }

  @objc func willSave(notification: NSNotification) {
    let moc = notification.object as! NSManagedObjectContext

    for managedObject in moc.updatedObjects.union(moc.insertedObjects) {
      if (managedObject.isUpdated || managedObject.isInserted) && managedObject.entity.attributesByName[updateDateProperty] != nil {
        managedObject.setValue(Date(), forKey: updateDateProperty)

        if UpdateListener.loggingEnabled {
          print("Updated \(updateDateProperty) for entity of name: \(managedObject.entity.name)")
        }
      }

      if managedObject.isInserted && managedObject.entity.attributesByName[insertDateProperty] != nil {
        managedObject.setValue(Date(), forKey: insertDateProperty)

        if UpdateListener.loggingEnabled {
          print("Set \(insertDateProperty) for entity of name: \(managedObject.entity.name)")
        }
      }
    }
  }
}
