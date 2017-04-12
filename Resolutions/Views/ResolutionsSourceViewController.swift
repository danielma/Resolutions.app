//
//  ResolutionsSourceViewController.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/22/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Cocoa

private var myContext = 0

class ResolutionsSourceViewController: NSViewController, NSOutlineViewDelegate {
  lazy var managedObjectContext: NSManagedObjectContext = {
    return (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
  }()

  @IBOutlet var sourcesTreeController: NSTreeController!
  @IBOutlet weak var outlineView: NSOutlineView!

  let coordinator = ResolutionsTableViewController.coordinator
  lazy var reposFetchRequest: NSFetchRequest<GithubRepoMO> = {
    let fetchRequest: NSFetchRequest<GithubRepoMO> = GithubRepoMO.fetchRequest()
    let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
    fetchRequest.sortDescriptors = [sortDescriptor]
    return fetchRequest
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    NotificationCenter.default.addObserver(self, selector: #selector(contextChange), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext)

    sourcesTreeController.content = treeContent()
    sourcesTreeController.addObserver(self, forKeyPath: #keyPath(NSTreeController.selectionIndexPaths), options: .new, context: &myContext)

    outlineView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
    sourcesTreeController.setSelectionIndexPath(IndexPath(index: 0))
    outlineView.delegate = self
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if context == &myContext {
      handleChangedSelection()
    } else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
  }

  internal func handleChangedSelection() {
    coordinator.setValue(sourcesTreeController.selectedObjects, forKey: "selectedObjects")
  }

  deinit {
    sourcesTreeController.removeObserver(self, forKeyPath: #keyPath(NSTreeController.selectionIndexPaths))
  }

  func contextChange() {
    let currentSelection = sourcesTreeController.selectionIndexPath
    sourcesTreeController.content = treeContent()
    sourcesTreeController.setSelectionIndexPath(currentSelection)
  }

  internal func treeContent() -> [NSDictionary] {
    let repos = try! managedObjectContext.fetch(reposFetchRequest)

    return [
      ["name": "INBOX"],
      ["name": "COMPLETE"],
      ["name": "GITHUB", "children": repos.map { RepoTreeNode($0) }]
    ]
  }

  // MARK: outline view

  func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
    return ResolutionsSourceTableRowView()
  }

  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    if let item = item as? NSTreeNode, item.representedObject as? RepoTreeNode != nil {
      return outlineView.make(withIdentifier: "RegularView", owner: self)
    } else {
      return outlineView.make(withIdentifier: "HeaderView", owner: self)
    }
  }
}

class RepoTreeNode: NSObject {
  let repo: GithubRepoMO
  let name: String?

  init(_ repo: GithubRepoMO) {
    self.repo = repo
    self.name = repo.name
  }

  var children: Array<RepoTreeNode>? {
    return nil
  }
}

class ResolutionsSourceTableRowView: NSTableRowView {
  override func drawSelection(in dirtyRect: NSRect) {
    NSColor(hue:0.56, saturation:0.66, brightness:0.88, alpha:1.00).setFill()
    let path = NSBezierPath(rect: dirtyRect)
    path.fill()
  }
}

/*

class ResolutionsSourceViewController: NSViewController {

  override func viewDidLoad() {
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
*/
