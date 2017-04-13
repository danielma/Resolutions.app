//
//  LabelMO+Resolutions.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/12/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import Cocoa

extension LabelMO {
  func getNSColor() -> NSColor? {
    if let color = color {
      return NSColor(hexString: color)
    } else {
      return nil
    }
  }
}
