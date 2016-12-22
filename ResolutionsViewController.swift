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
  let resolutionsRequest = Resolution
    .filter(Column("completedAt") == nil)
    .order(Column("createdAt").asc)
  
  @IBOutlet weak var tableView: NSTableView!

  override func viewDidLoad() {
    super.viewDidLoad()

    GithubPoller.sharedInstance.start()

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
  @IBOutlet weak var checkbox: NSButton!
  @IBOutlet weak var titleButton: NSButton!
  @IBOutlet weak var groupingButton: ResolutionGroupingButton!

  @IBAction func titleButtonClicked(_ sender: NSButton) {
    if let url = resolution.url {
      NSWorkspace.shared().open(url)
    }
  }

  @IBAction func checkboxClicked(_ sender: NSButton) {
    dbQueue.inDatabase { db in
      resolution.completedAt = Date()

      if resolution.hasPersistentChangedValues {
        try! resolution.save(db)
      }
    }
  }

  var resolution: Resolution!

  func configure(_ resolution: Resolution?) {
    guard let resolution = resolution else { return }

    self.resolution = resolution

    titleButton.title = resolution.name
    groupingButton.customTitle = resolution.grouping ?? ""
    checkbox.state = resolution.completed ? NSOnState : NSOffState
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
