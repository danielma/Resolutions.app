//
//  CoreDataViewController.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/3/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import Foundation
import Cocoa

class CoreDataViewController: NSViewController {
  lazy var managedObjectContext: NSManagedObjectContext = {
    return (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
  }()

//  @IBOutlet var resolutionsArrayController: NSArrayController!

  override func viewDidLoad() {
    super.viewDidLoad()

    if !isTestMode {
      GithubPoller.sharedInstance.start()
    }

//
//    let repo = GithubRepoMO(context: managedObjectContext)
//    let resolution = ResolutionMO(context: managedObjectContext)
//
//    repo.name = "ministrycentered/giving"
//    repo.url = "https://github.com/ministrycentered/giving"
//
//    resolution.name = "The new Hotness"
//    resolution.remoteIdentifier = "shepa"
//    resolution.repo = repo
//
//    do {
//      print("create object")
//      try managedObjectContext.save()
//    } catch {
//      fatalError("Failure to save contexxt: \(error)")
//    }

//    let resolutionsFetch: NSFetchRequest<ResolutionMO> = NSFetchRequest(entityName: "Resolution")
//
//    let fetchedResolutions: [ResolutionMO]!
//
//    do {
//      fetchedResolutions = try moc.fetch(resolutionsFetch)
//    } catch {
//      fatalError("Failed to fetch resolutions: \(error)")
//    }
//
//    resolutionsArrayController.content = fetchedResolutions
//  }
  }
}
