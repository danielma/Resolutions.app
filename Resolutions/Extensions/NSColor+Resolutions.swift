//
//  NSColor+Resolutions.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/12/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import Foundation
import Cocoa

extension NSColor {
  convenience init(hexString: String) {
    if let hex = Int(hexString, radix: 16) {
      self.init(hex: hex)
    } else {
      self.init()
    }
  }

  convenience init(hex: Int) {
    let red = Double((hex >> 16 & 0xFF))
    let green = Double((hex >> 8 & 0xFF))
    let blue = Double((hex >> 0 & 0xFF))

    self.init(
      red: CGFloat(red / 255.0),
      green: CGFloat(green / 255.0),
      blue: CGFloat(blue / 255.0),
      alpha: 1
    )
  }

  // http://stackoverflow.com/a/42907635/4499924
  func isLight() -> Bool {
    guard let components = cgColor.components else { return false }
    let redBrightness = components[0] * 299
    let greenBrightness = components[1] * 587
    let blueBrightness = components[2] * 114
    let brightness = (redBrightness + greenBrightness + blueBrightness) / 1000
    return brightness > 0.5
  }
}
