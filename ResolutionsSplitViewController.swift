//
//  ResolutionsSplitViewController.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/22/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Cocoa
import GRDB

class ResolutionsSplitViewController: NSSplitViewController {
  var fetchedResolutionsController: FetchedRecordsController<Resolution>!
  let resolutionsRequest = Resolution.order(Column("completedAt").asc, Column("createdAt").asc)

  override func viewDidLoad() {
    super.viewDidLoad()
    
    GithubPoller.sharedInstance.start()
    
    setupFetchedRecordsController()
  }

  func setupFetchedRecordsController() {
    try! fetchedResolutionsController = FetchedRecordsController<Resolution>(dbQueue, request: resolutionsRequest)

    fetchedResolutionsController.trackChanges(
      recordsDidChange: { [unowned self] _ in
        self.updateChildViewControllers()
      }
    )

    try! fetchedResolutionsController.performFetch()
    updateChildViewControllers(initial: true)
  }

  func updateChildViewControllers(initial: Bool = false) {
    childViewControllers.forEach({ controller in
      let controller = controller as! ResolutionsSplitViewControllerChild

      if initial {
        controller.fetchedResolutionsControllerDidPopulate(self.fetchedResolutionsController)
      } else {
        controller.fetchedResolutionsControllerDidChange(self.fetchedResolutionsController)
      }
    })
  }

  func filter(_ predicate: SQLExpressible) {
    try! fetchedResolutionsController.setRequest(resolutionsRequest.filter(predicate))
  }
}

protocol ResolutionsSplitViewControllerChild {
  func fetchedResolutionsControllerDidChange(_ controller: FetchedRecordsController<Resolution>) -> Void
  func fetchedResolutionsControllerDidPopulate(_ controller: FetchedRecordsController<Resolution>) -> Void
}
