//
//  ResolutionsViewController.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/19/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Cocoa
import GRDB

class ResolutionsViewController: NSViewController {
  var fetchedResolutionsController: FetchedRecordsController<Resolution>!
  let resolutionsRequest = Resolution.order(Column("createdAt").asc)
  
  @IBOutlet weak var tableView: NSTableView!

  override func viewDidLoad() {
    super.viewDidLoad()

    try! setupDatabase()

    setupFetchedRecordsController()
    
    tableView.delegate = self
    tableView.dataSource = self
    // Do view setup here.
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
        self.tableView.reloadData()
      }
    )

    try! fetchedResolutionsController.performFetch()
  }
}

extension ResolutionsViewController: NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return fetchedResolutionsController.fetchedRecords?.count ?? 0
  }
}

extension ResolutionsViewController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let cell = tableView.make(withIdentifier: "ResolutionTableCellView", owner: self) as! ResolutionTableCellView
    let resolution = fetchedResolutionsController.fetchedRecords?[row]

    cell.configure(resolution)

    return cell
  }
}

class ResolutionTableCellView: NSTableCellView {
  @IBOutlet weak var label: NSTextField!

  func configure(_ resolution: Resolution?) {
    guard let resolution = resolution else { return }
    
    label.stringValue = resolution.name
  }
}
