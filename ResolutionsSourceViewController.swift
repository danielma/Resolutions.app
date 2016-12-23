//
//  ResolutionsSourceViewController.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/22/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Cocoa
import GRDB

typealias GroupedGroupingList = (String, [String])

class ResolutionsSourceViewController: NSViewController {
  @IBOutlet weak var outlineView: NSOutlineView!

  var groupings: [String] = []
  var groupedGroupings: [GroupedGroupingList] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
    
    outlineView.dataSource = self
    outlineView.delegate = self
//    outlineView.selectionHighlightStyle = .none
  }
}

extension ResolutionsSourceViewController: ResolutionsSplitViewControllerChild {
  func fetchedResolutionsControllerDidPopulate(_ controller: FetchedRecordsController<Resolution>) {
    var newGroupings: [String] = []

    dbQueue.inDatabase { db in
      try! newGroupings = String.fetchAll(db, "SELECT DISTINCT grouping FROM resolutions ORDER BY LOWER(grouping)")
    }

    guard groupings != newGroupings else { return }
    groupings = newGroupings

    groupedGroupings = [("All", ["Inbox", "Completed"]), ("Github", groupings)]

    outlineView.reloadData()
    outlineView.expandItem(nil, expandChildren: true)
  }
  
  func fetchedResolutionsControllerDidChange(_ controller: FetchedRecordsController<Resolution>) {
    fetchedResolutionsControllerDidPopulate(controller)
  }
}

extension ResolutionsSourceViewController: NSOutlineViewDataSource {
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    if item == nil {
      return groupedGroupings.count
    } else if let item = item as? GroupedGroupingList {
      return item.1.count
    } else {
      return 0
    }
  }

  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    if item == nil {
      return groupedGroupings[index]
    } else if let item = item as? GroupedGroupingList {
      return item.1[index]
    } else {
      return ""
    }
  }

  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    if let item = item as? GroupedGroupingList {
      return item.1.count > 0
    }

    return false
  }
}

extension ResolutionsSourceViewController: NSOutlineViewDelegate {
  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    if let item = item as? String {
      if let view = outlineView.make(withIdentifier: "DataCell", owner: self) as? NSTableCellView {
        view.textField?.stringValue = item

        return view
      }
    } else if let item = item as? GroupedGroupingList {
      if let view = outlineView.make(withIdentifier: "HeaderCell", owner: self) as? NSTableCellView {
        view.textField?.stringValue = item.0

        return view
      }
    }

    return nil
  }

  func outlineViewSelectionDidChange(_ notification: Notification) {
    guard let outlineView = notification.object as? NSOutlineView else { return }

    let selectedIndex = outlineView.selectedRow
    let parentController = parent as! ResolutionsSplitViewController

    if let grouping = outlineView.item(atRow: selectedIndex) as? String {
      if grouping == "Inbox" {
        parentController.filter(Column("completedAt") == nil)
      } else if grouping == "Completed" {
        parentController.filter(Column("completedAt") != nil)
      } else {
        parentController.filter(Column("grouping") == grouping)
      }
    }
  }
}
