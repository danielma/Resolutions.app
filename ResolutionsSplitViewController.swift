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
  let resolutionsRequest = Resolution
    .filter(Column("completedAt") == nil)
    .order(Column("createdAt").asc)

  override func viewDidLoad() {
    super.viewDidLoad()
    
    GithubPoller.sharedInstance.start()
    
    setupFetchedRecordsController()
  }
  
  func setupFetchedRecordsController() {
    try! fetchedResolutionsController = FetchedRecordsController<Resolution>(dbQueue, request: resolutionsRequest)

    fetchedResolutionsController.trackChanges(
//      tableViewEvent: { [unowned self] (controller, record, event) in
//        switch event {
//        case .insertion(let indexPath):
//          self.tableView.insertRows(at: [indexPath], with: .fade)
//        case .deletion(let indexPath):
//          self.tableView.deleteRows(at: [indexPath], with: .fade)
//        case .update(let indexPath, _):
//          if let cell = self.tableView.cellForRow(at: indexPath) {
//            self.configure(cell as! ReviewListTableViewCell, at: indexPath)
//          }
//        case .move(let indexPath, let newIndexPath, _):
//          self.tableView.deleteRows(at: [indexPath], with: .fade)
//          self.tableView.insertRows(at: [newIndexPath], with: .fade)
//        }
//      },

      recordsDidChange: { [unowned self] _ in
        self.updateChildViewControllers()
      }
    )

    try! fetchedResolutionsController.performFetch()
    updateChildViewControllers()
  }

  func updateChildViewControllers() {
    childViewControllers.forEach({ controller in
      (controller as! ResolutionsSplitViewControllerChild).fetchedResolutionsControllerDidChange(self.fetchedResolutionsController)
    })
  }
}

protocol ResolutionsSplitViewControllerChild {
  func fetchedResolutionsControllerDidChange(_ controller: FetchedRecordsController<Resolution>) -> Void
}
