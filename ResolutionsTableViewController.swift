//
//  ResolutionsTableViewController.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/4/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//


import Cocoa

class ResolutionsTableViewController: NSViewController {
  lazy var managedObjectContext: NSManagedObjectContext = {
    return (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
  }()
}
