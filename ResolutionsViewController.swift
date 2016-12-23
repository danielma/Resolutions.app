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
  @IBOutlet weak var tableView: NSTableView!
  var fetchedResolutionsController: FetchedRecordsController<Resolution>?

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.delegate = self
    tableView.dataSource = self
    // Do view setup here.
  }
}

extension ResolutionsViewController: ResolutionsSplitViewControllerChild {
  func fetchedResolutionsControllerDidPopulate(_ controller: FetchedRecordsController<Resolution>) {
    fetchedResolutionsControllerDidChange(controller)
  }

  func fetchedResolutionsControllerDidChange(_ controller: FetchedRecordsController<Resolution>) {
    self.fetchedResolutionsController = controller
    tableView.reloadData()
  }
}

extension ResolutionsViewController: NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return fetchedResolutionsController?.fetchedRecords?.count ?? 0
  }
}

extension ResolutionsViewController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let cell = tableView.make(withIdentifier: "ResolutionTableCellView", owner: self) as! ResolutionTableCellView
    let resolution = fetchedResolutionsController?.fetchedRecords?[row]

    cell.configure(resolution, tableView: tableView)

    return cell
  }
}

class ResolutionTableCellView: NSTableCellView {
  @IBOutlet weak var checkbox: NSButton!
  @IBOutlet weak var titleButton: NSButton!
  @IBOutlet weak var groupingButton: ResolutionGroupingButton!

  var tableView: NSTableView!
  var row: Int!

  @IBAction func titleButtonClicked(_ sender: NSButton) {
    if let url = resolution.url {
      NSWorkspace.shared().open(url)
    }
  }

  @IBAction func checkboxClicked(_ sender: NSButton) {
    let row = tableView.row(for: self)
    let indexSet = IndexSet(integer: row)
    NSAnimationContext.runAnimationGroup({ (context) in
      tableView.removeRows(at: indexSet, withAnimation: .slideUp)
    }) { 
      dbQueue.inDatabase { db in
        self.resolution.completedAt = Date()

        if self.resolution.hasPersistentChangedValues {
          try! self.resolution.save(db)
        }
      }
    }
  }

  var resolution: Resolution!

  func configure(_ resolution: Resolution?, tableView: NSTableView) {
    guard let resolution = resolution else { return }

    self.tableView = tableView
    self.resolution = resolution

    titleButton.title = resolution.name
    groupingButton.customTitle = resolution.grouping ?? ""
    checkbox.state = resolution.completed ? NSOnState : NSOffState
  }
}

class ResolutionTitleButton: NSButton {
  let cursor = NSCursor.pointingHand()

  override func resetCursorRects() {
    addCursorRect(bounds, cursor: cursor)
  }
}

class ResolutionGroupingButton: NSButton {
  override func draw(_ dirtyRect: NSRect) {
    NSColor(red: 0, green: 0, blue: 0, alpha: 0.1).set()

    let bPath = NSBezierPath(roundedRect: dirtyRect, xRadius: 4, yRadius: 4)
    bPath.fill()

    super.draw(dirtyRect)
  }

  var _customTitle = ""
  var customTitle: String {
    get { return _customTitle }
    set {
      _customTitle = newValue
      updateAttributedTitle()
    }
  }

  func updateAttributedTitle() {
    attributedTitle = NSAttributedString(
      string: _customTitle,
      attributes: [
        NSForegroundColorAttributeName: NSColor(red: 0, green: 0, blue: 0, alpha: 0.5),
        NSFontAttributeName: NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize())
      ]
    )
  }
}

class RSResolutionGroupingCell: NSButtonCell {
  static let padding = 4

  override func drawTitle(_ title: NSAttributedString, withFrame frame: NSRect, in controlView: NSView) -> NSRect {
    var newFrame = frame
    newFrame.origin.x += CGFloat(RSResolutionGroupingCell.padding)
    return super.drawTitle(title, withFrame: newFrame, in: controlView)
  }
  
  override var cellSize: NSSize {
    let original = super.cellSize
    return NSSize(width: original.width + CGFloat(RSResolutionGroupingCell.padding * 2), height: original.height)
  }
}
