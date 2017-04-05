//
//  ResolutionsSourceViewController.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/22/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Cocoa

class ResolutionsSourceViewController: NSViewController {
  lazy var managedObjectContext: NSManagedObjectContext = {
    return (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
  }()

  @IBOutlet var sourcesTreeController: NSTreeController!

  override func viewDidLoad() {
    super.viewDidLoad()

    let fetchRequest: NSFetchRequest<GithubRepoMO> = GithubRepoMO.fetchRequest()

    let repos = try! managedObjectContext.fetch(fetchRequest)
    let nodes = [
      ["name": "Inbox"],
      ["name": "Complete"],
      ["name": "Github", "children": repos.map { TreeNode($0) }]
    ]

    sourcesTreeController.content = nodes
  }
}

fileprivate class TreeNode: NSObject {
  let repo: GithubRepoMO
  let name: String?
  
  init(_ repo: GithubRepoMO) {
    self.repo = repo
    self.name = repo.name
  }

  var children: Array<TreeNode>? {
    return nil
  }
}

/*

import Cocoa
import GRDB

typealias GroupedroupingList = (String, [String])

class ResolutionsSourceViewController: NSViewController {
  @IBOutlet weak var reloadButton: NSButton!
  @IBAction func reloadButtonClicked(_ sender: Any) {
    GithubPoller.sharedInstance.forceUpdate()
    animateReloadButton()
  }

  @IBOutlet weak var outlineView: NSOutlineView!

  var groupings: [String] = []
  var groupedGroupings: [GroupedGroupingList] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.

    outlineView.dataSource = self
    outlineView.delegate = self

    NotificationCenter.default.addObserver(forName: GithubPoller.forcedUpdateNotificationName, object: nil, queue: nil) { (_) in
      self.animateReloadButton()
    }
  }

  func animateReloadButton() {
    if reloadButton.layer?.animation(forKey: "rotation") == nil {
      let frame = reloadButton.layer!.frame
      let center = CGPoint(x: frame.midX, y: frame.midY)
      reloadButton.layer!.position = center
      reloadButton.layer!.anchorPoint = CGPoint(x: 0.5, y: 0.5)

      let animate = CABasicAnimation(keyPath: "transform.rotation")
      animate.duration = 1
      animate.repeatCount = 1
      animate.fromValue = 0.0
      animate.toValue = Float(-M_PI * 2.0)
      reloadButton.layer?.add(animate, forKey: "rotation")
    }
  }
}

extension ResolutionsSourceViewController: ResolutionsSplitViewControllerChild {
  func fetchGroupings() -> [String] {
    return dbQueue.inDatabase { db in
      return try! String.fetchAll(db, "SELECT DISTINCT grouping FROM resolutions ORDER BY LOWER(grouping)")
    }
  }

  func fetchedResolutionsControllerDidPopulate(_ controller: FetchedRecordsController<Resolution>) {
    groupings = fetchGroupings()

    groupedGroupings = [("All", ["Inbox", "Completed"]), ("Github", groupings)]

    outlineView.reloadData()
    outlineView.expandItem(nil, expandChildren: true)

    let inboxRow = outlineView.row(forItem: "Inbox")
    let indexSet = IndexSet(integer: inboxRow)
    outlineView.selectRowIndexes(indexSet, byExtendingSelection: true)
  }
  
  func fetchedResolutionsControllerDidChange(_ controller: FetchedRecordsController<Resolution>) {
    let newGroupings = fetchGroupings()

    guard groupings != newGroupings else { return }

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

  func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
    return ResolutionsSourceTableRowView()
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

class ResolutionsSourceTableRowView: NSTableRowView {
  override func drawSelection(in dirtyRect: NSRect) {
    NSColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.2).setFill()
    let path = NSBezierPath(rect: dirtyRect)
    path.fill()
  }
}

 */
