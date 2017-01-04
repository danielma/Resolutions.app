//
//  AppDelegate.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/19/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  var mainWindowController: NSWindowController?

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    UserDefaults.standard.register(defaults: [
      "githubToken": "",
      "githubUsername": "",
      "githubLastEventReadId": 0,
      "githubUseMagicComments": false,
      "githubMagicCommentString": "",
      "dockIconShowInboxCount": false,
    ])
  }

  @IBAction func reloadMenuClicked(_ sender: Any) {
    GithubPoller.sharedInstance.forceUpdate()
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if (flag) { return false }
    
    mainWindowController?.window?.makeKeyAndOrderFront(self)
    return true
  }
}

