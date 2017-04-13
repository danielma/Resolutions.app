//
//  RSWindowController.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/19/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Cocoa
fileprivate var myContext = 1

class RSWindowController: NSWindowController {
  @IBOutlet weak var syncButton: NSButton!
  @IBOutlet weak var currentViewLabel: NSTextField!
  @IBAction func syncButtonClicked(_ sender: Any) {
    GithubPoller.sharedInstance.forceUpdate()
  }

  @IBAction func toggleHeaderClicked(_ sender: Any) {
    if let button = sender as? NSButton {
      button.image = #imageLiteral(resourceName: "Unfold")
      ResolutionsTableViewController.coordinator["headersVisible"] = true
    }
  }

  let syncButtonLayer = CALayer()

  override func awakeFromNib() {
    super.awakeFromNib()

    self.windowFrameAutosaveName = "RSWindowAutosave"
  }
  
  override func windowDidLoad() {
    super.windowDidLoad()

    window?.delegate = self

    (NSApp.delegate as! AppDelegate).mainWindowController = self
    window?.titleVisibility = .hidden
    window?.isOpaque = false
    window?.contentView?.wantsLayer = true
    window?.contentView?.layer?.masksToBounds = true
//    window?.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)!

//    window?.titlebarAppearsTransparent = true
//    window?.isMovableByWindowBackground = true
//    window?.toolbar?.showsBaselineSeparator = false
    NotificationCenter.default.addObserver(forName: GithubPoller.updateStartedNotificationName, object: nil, queue: nil) { (_) in
      self.animateSyncButton()
    }

    NotificationCenter.default.addObserver(forName: GithubPoller.updateFinishedNotificationName, object: nil, queue: nil) { (_) in
      self.stopAnimateSyncButton()
    }

    ResolutionsTableViewController.coordinator.addObserver(self, forKeyPath: "selectedObjects", options: .new, context: &myContext)

    let reloadImage = #imageLiteral(resourceName: "reload")
    syncButton.wantsLayer = true
    syncButtonLayer.contents = reloadImage
    let buttonSize = syncButton.bounds.size
    let bounds = NSRect(
      origin: NSPoint(
        x: (buttonSize.width / 2) - (reloadImage.size.width / 2),
        y: (buttonSize.height / 2) - (reloadImage.size.height / 2)
      ),
      size: reloadImage.size
    )
    syncButtonLayer.frame = bounds
    syncButton.layer?.addSublayer(syncButtonLayer)
  }

  func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager? {
    return (NSApplication.shared().delegate as! AppDelegate).windowWillReturnUndoManager(window: window)
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if context == &myContext && keyPath == "selectedObjects" {
      handleSelectedObjectsChanged()
    } else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
  }

  private func handleSelectedObjectsChanged() {
    guard let selectedObjects = ResolutionsTableViewController.coordinator.value(forKey: "selectedObjects") as? Array<Any> else { return }
    
    if let selectedTreeNodes = selectedObjects as? Array<RepoTreeNode> {
      guard let selectedObject = selectedTreeNodes.first,
        let name = selectedObject.repo.name else { return }

      currentViewLabel.stringValue = name
    } else {
      guard let selectedObject = selectedObjects[0] as? NSDictionary,
        let name = selectedObject.value(forKey: "name") as? String
        else { return }

      currentViewLabel.stringValue = name
    }
  }

  var buttonIsRotating = false
  func animateSyncButton() {
    buttonIsRotating = true
    if syncButtonLayer.animation(forKey: "rotation") == nil {
//      let frame = syncButtonLayer.frame
//      let center = CGPoint(x: frame.midX, y: frame.midY)
//      syncButtonLayer.position = center
      syncButtonLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)

      let animate = CABasicAnimation(keyPath: "transform.rotation")
      animate.duration = 1
      animate.repeatCount = 40
      animate.fromValue = 0.0
      animate.toValue = 1 * Float(Double.pi * 2.0)
//      animate.delegate = self
      syncButtonLayer.add(animate, forKey: "rotation")
    }
  }

  func stopAnimateSyncButton() {
    if syncButtonLayer.animation(forKey: "rotation") != nil {
      buttonIsRotating = false
//      syncButtonLayer.frame = syncButtonLayer.presentation()!.frame
      DispatchQueue.main.async {
        sleep(1)
        if !self.buttonIsRotating {
          self.syncButtonLayer.removeAnimation(forKey: "rotation")
        }
      }
    }
  }
}

extension RSWindowController: NSWindowDelegate {
}

class RSWindow: NSWindow {
//  override init(contentRect: NSRect, styleMask style: NSWindowStyleMask, backing bufferingType: NSBackingStoreType, defer flag: Bool) {
//    super.init(contentRect: contentRect, styleMask: style, backing: bufferingType, defer: flag)
//
//    let visualEffectView = NSVisualEffectView(frame: NSMakeRect(0, 0, 0, 10))//<---the width and height is set to 0, as this doesn't matter.
//    visualEffectView.wantsLayer = true
//    visualEffectView.material = NSVisualEffectMaterial.ultraDark//Dark,MediumLight,PopOver,UltraDark,AppearanceBased,Titlebar,Menu
//    visualEffectView.blendingMode = NSVisualEffectBlendingMode.behindWindow//I think if you set this to WithinWindow you get the effect safari has in its TitleBar. It should have an Opaque background behind it or else it will not work well
//    visualEffectView.state = NSVisualEffectState.active//FollowsWindowActiveState,Inactive
//    self.contentView = visualEffectView/*you can also add the visualEffectView to the contentview, just add some width and height to the visualEffectView, you also need to flip the view if you like to work from TopLeft, do this through subclassing*/
//  }
//  override func awakeFromNib() {
//  }

//  override var contentView: NSView? {
//    set {}
//    get {
//      if let v = super.contentView {
//        return NSVisualEffectView(frame: v.frame)
//      } else {
//        let view = NSVisualEffectView(frame: NSMakeRect(0, 0, 0, 0))
//        view.blendingMode = .behindWindow
//        view.material = .dark
//        view.state = .followsWindowActiveState
//        return view
//      }
//    }
//  }
}
//
extension RSWindowController: CAAnimationDelegate {
//  func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
//    if flag {
//      let animate = CABasicAnimation(keyPath: "transform.rotation")
//      animate.duration = 1
//      animate.repeatCount = 40
//      animate.fromValue = 0.0
//      animate.toValue = 1 * Float(Double.pi * 2.0)
//      animate.delegate = self
//      syncButtonLayer.add(animate, forKey: "rotation")
//    }
//  }
}
