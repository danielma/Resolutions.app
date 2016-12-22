//
//  ResolutionsSourceViewController.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/22/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Cocoa

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

    dbQueue.inDatabase { (db) in
      groupings = try! String.fetchAll(db, "SELECT DISTINCT grouping FROM resolutions ORDER BY grouping ASC")
    }

    groupedGroupings.append(("GITHUB", groupings))

    outlineView.reloadData()
    outlineView.expandItem(nil, expandChildren: true)
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
//    } else if let item = item as? [GroupedGroupingList] {
//      return item[index]
    } else if let item = item as? GroupedGroupingList {
      return item.1[index]
    } else {
      return ""
    }
  }

  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    if item is String {
      return false
    }

    return true
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
}
