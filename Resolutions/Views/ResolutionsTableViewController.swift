//
//  ResolutionsTableViewController.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/4/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

fileprivate var myContext = 0

import Cocoa

public class UpcaseFormatter: Formatter {
  override public func string(for obj: Any?) -> String? {
    if let string = obj as? String {
      return string.uppercased()
    } else if let string = obj as? NSAttributedString {
      return string.string.uppercased()
    } else {
      return nil
    }
  }
}

public class LabelFormatter: Formatter {
  public override func string(for obj: Any?) -> String? {
    if let labels = obj as? Set<LabelMO> {
      return labels.map { $0.name ?? "" }.joined(separator: ", ")
    } else if obj != nil {
      return "HALP"
    } else {
      return nil
    }
  }
}

class ResolutionsTableViewController: NSViewController, NSTableViewDelegate {
  lazy var managedObjectContext: NSManagedObjectContext = {
    return (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
  }()

  static let dockIconShowSelectedViewCountKey = "dockIconShowSelectedViewCount"

  @IBOutlet var arrayController: NSArrayController!
  @IBOutlet weak var tableView: NSTableView!
  @IBAction func doubleClicked(_ sender: Any) {
    guard let objects = arrayController.arrangedObjects as? [ResolutionMO],
      tableView.clickedRow > -1 else {
      return
    }
    let selectedObject = objects[tableView.clickedRow]
    if let str = selectedObject.url, let url = URL(string: str) {
      NSWorkspace.shared().open(url)
    }
  }
  @IBAction func clickRepoButton(_ sender: Any) {
    guard let button = sender as? NSButton,
      let url = URL(string: button.alternateTitle) else {
      return
    }

    NSWorkspace.shared().open(url)
  }

  static let coordinator: NSMutableDictionary = [
    "selectedObjects": [],
    "headersVisible": false,
    "checkShouldRemove": true,
  ]

  override func viewDidLoad() {
    super.viewDidLoad()

    ResolutionsTableViewController.coordinator.addObserver(self, forKeyPath: "selectedObjects", options: .new, context: &myContext)
    ResolutionsTableViewController.coordinator.addObserver(self, forKeyPath: "headersVisible", options: .new, context: &myContext)
    NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(updateDockIcon), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext)

    tableView.delegate = self
    tableView.target = self
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if context == &myContext {
      if keyPath == "selectedObjects" {
        handleSelectedObjectsChanged()
      } else {
        debugPrint("headers visible")
      }
    } else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
  }

  internal func handleSelectedObjectsChanged() {
    guard let selectedObjects = ResolutionsTableViewController.coordinator.value(forKey: "selectedObjects") as? Array<Any> else { return }

    if let selectedTreeNodes = selectedObjects as? Array<RepoTreeNode> {
      guard let selectedObject = selectedTreeNodes.first else { return }

      ResolutionsTableViewController.coordinator["checkShouldRemove"] = false
      arrayController.filterPredicate = NSPredicate(format: "repo = %@", argumentArray: [selectedObject.repo])
    } else {
      guard let selectedObject = selectedObjects[0] as? NSDictionary,
        let name = selectedObject.value(forKey: "name") as? String
        else { return }

      let lowercaseName = name.lowercased()

      if lowercaseName == "inbox" {
        ResolutionsTableViewController.coordinator["checkShouldRemove"] = true
        arrayController.filterPredicate = NSPredicate(format: "completedDate = nil")
      } else if lowercaseName == "complete" {
        ResolutionsTableViewController.coordinator["checkShouldRemove"] = true
        arrayController.filterPredicate = NSPredicate(format: "completedDate != nil")
      }
    }

    updateDockIcon()
  }
}

extension ResolutionsTableViewController {
  internal func updateDockIcon() {
    let showSelectedCount = UserDefaults.standard.value(forKey: ResolutionsTableViewController.dockIconShowSelectedViewCountKey) as? Bool ?? false

    guard showSelectedCount,
      let records = arrayController.arrangedObjects as? Array<ResolutionMO>
      else { return emptyDockTile() }

    let notCompletedRecords = records.filter({ !$0.completed })
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
}

class ResolutionsTableView: NSTableView {
  override func awakeFromNib() {
    super.awakeFromNib()
    
  }
  override var allowsVibrancy: Bool {
    set {}
    get { return false }
  }

}

class CheckboxTableCell: NSTableCellView {
  var completed: Bool {
    get {
      if let resolution = objectValue as? ResolutionMO {
        return resolution.completed
      } else {
        return false
      }
    }
    set {
      guard let resolution = objectValue as? ResolutionMO,
        (ResolutionsTableViewController.coordinator["checkShouldRemove"] as? Bool) == true
        else { return }

      if let rowView = (superview as? NSTableRowView),
        let tableView = rowView.superview as? NSTableView {
        let indexSet = IndexSet(integer: tableView.row(for: rowView))
        NSAnimationContext.runAnimationGroup({ context in
          tableView.removeRows(at: indexSet, withAnimation: .slideUp)
        }) {
          resolution.completed = newValue
        }
      } else {
        resolution.completed = newValue
      }
    }
  }

  override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
    if key == "completed" {
      var set = Set<String>()
      set.insert("objectValue.completed")
      return set
    } else {
      return super.keyPathsForValuesAffectingValue(forKey: key)
    }
  }
}
