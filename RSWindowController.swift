//
//  RSWindowController.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/19/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Cocoa

class RSWindowController: NSWindowController {
  var notificationsPoller: RequestPoller?

  @IBAction func refreshButtonClicked(_ sender: NSButton) {
    if let poller = notificationsPoller {
      poller.forceRequest()
    }
  }
  
  override func windowDidLoad() {
    super.windowDidLoad()

    window?.delegate = self
    window?.titleVisibility = .hidden
//    window?.titlebarAppearsTransparent = true
//    window?.isMovableByWindowBackground = true

    notificationsPoller = GithubAPIClient.sharedInstance.pollNotifications()
      .map { print($0) }
      .start()
  }
}

extension RSWindowController: NSWindowDelegate {
  func windowWillClose(_ notification: Notification) {
    if let poller = notificationsPoller { poller.stop() }
  }
}

class RSWindow: NSWindow {

  override func awakeFromNib() {
//    let visualEffectView = NSVisualEffectView(frame: NSMakeRect(0, 0, 0, 10))//<---the width and height is set to 0, as this doesn't matter.
//    visualEffectView.material = NSVisualEffectMaterial.appearanceBased//Dark,MediumLight,PopOver,UltraDark,AppearanceBased,Titlebar,Menu
//    visualEffectView.blendingMode = NSVisualEffectBlendingMode.withinWindow//I think if you set this to WithinWindow you get the effect safari has in its TitleBar. It should have an Opaque background behind it or else it will not work well
//    visualEffectView.state = NSVisualEffectState.active//FollowsWindowActiveState,Inactive
//    self.contentView = visualEffectView/*you can also add the visualEffectView to the contentview, just add some width and height to the visualEffectView, you also need to flip the view if you like to work from TopLeft, do this through subclassing*/
  }
}
