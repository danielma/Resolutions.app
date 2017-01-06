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

  static let dockIconShowSelectedViewCountKey = "dockIconShowSelectedViewCount"

  override func viewDidLoad() {
    super.viewDidLoad()

    if !isTestMode {
      GithubPoller.sharedInstance.start()
    }

    NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsChanged), name: UserDefaults.didChangeNotification, object: nil)

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
    updateDockIcon()

    childViewControllers.forEach({ controller in
      let controller = controller as! ResolutionsSplitViewControllerChild

      if initial {
        controller.fetchedResolutionsControllerDidPopulate(self.fetchedResolutionsController)
      } else {
        controller.fetchedResolutionsControllerDidChange(self.fetchedResolutionsController)
      }
    })
  }

  internal func updateDockIcon() {
    let showSelectedCount = UserDefaults.standard.value(forKey: ResolutionsSplitViewController.dockIconShowSelectedViewCountKey) as? Bool ?? false

    guard showSelectedCount,
      let records = fetchedResolutionsController.fetchedRecords
      else { return emptyDockTile() }

    let notCompletedRecords = records.filter({ $0.completedAt == nil })
    let count = notCompletedRecords.count

    guard count > 0 else { return emptyDockTile() }

    NSApplication.shared().dockTile.badgeLabel = String(describing: count)
  }

  internal func emptyDockTile() {
    NSApplication.shared().dockTile.badgeLabel = nil
  }

  internal func userDefaultsChanged() {
    updateDockIcon()
  }

  func filter(_ predicate: SQLExpressible) {
    try! fetchedResolutionsController.setRequest(resolutionsRequest.filter(predicate))
  }
}

protocol ResolutionsSplitViewControllerChild {
  func fetchedResolutionsControllerDidChange(_ controller: FetchedRecordsController<Resolution>) -> Void
  func fetchedResolutionsControllerDidPopulate(_ controller: FetchedRecordsController<Resolution>) -> Void
}
