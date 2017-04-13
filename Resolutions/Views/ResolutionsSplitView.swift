//
//  ResolutionsSplitView.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/13/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import Foundation
import Cocoa

class ResolutionsSplitView: NSSplitView {
  override func drawDivider(in rect: NSRect) {
  }

  override var dividerColor: NSColor {
    return NSColor.clear
  }
}
