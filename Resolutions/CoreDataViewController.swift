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
  @IBOutlet var resolutionsArrayController: NSArrayController!

  override func viewDidLoad() {
    super.viewDidLoad()

    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate

    let moc = appDelegate.managedObjectContext

//
//    let repo = GithubRepoMO(context: moc)
//    let resolution = ResolutionMO(context: moc)
//
//    repo.name = "ministrycentered/giving"
//    repo.url = "https://github.com/ministrycentered/giving"
//
//    resolution.name = "Superdude"
//    resolution.remoteIdentifier = "kappa"
//    resolution.repo = repo
//
//    do {
//      try moc.save()
//    } catch {
//      fatalError("Failure to save contexxt: \(error)")
//    }

    let resolutionsFetch: NSFetchRequest<ResolutionMO> = NSFetchRequest(entityName: "Resolution")

    let fetchedResolutions: [ResolutionMO]!

    do {
      fetchedResolutions = try moc.fetch(resolutionsFetch)
    } catch {
      fatalError("Failed to fetch resolutions: \(error)")
    }

    resolutionsArrayController.content = fetchedResolutions
    debugPrint(resolutionsArrayController.content)
  }
}
