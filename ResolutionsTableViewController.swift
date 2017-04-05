//
//  ResolutionsTableViewController.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/4/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

fileprivate var myContext = 0

import Cocoa

class ResolutionsTableViewController: NSViewController {
  lazy var managedObjectContext: NSManagedObjectContext = {
    return (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
  }()
  
  @IBOutlet var arrayController: NSArrayController!

  static let coordinator: NSMutableDictionary = ["selectedObjects": []]

  override func viewDidLoad() {
    super.viewDidLoad()

    ResolutionsTableViewController.coordinator.addObserver(self, forKeyPath: "selectedObjects", options: .new, context: &myContext)
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if context == &myContext {
      handleSelectedObjectsChanged()
    } else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
  }

  internal func handleSelectedObjectsChanged() {
    guard let selectedObjects = ResolutionsTableViewController.coordinator.value(forKey: "selectedObjects") as? Array<RepoTreeNode> else { return }
    guard let selectedObject = selectedObjects.first else { return }

    arrayController.filterPredicate = NSPredicate(format: "repo = %@", argumentArray: [selectedObject.repo])
  }
}
