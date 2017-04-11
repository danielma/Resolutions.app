//
//  RSResolutionCheckbox.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/21/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Cocoa

@IBDesignable class RSResolutionCheckboxCell: NSButtonCell {
  required init(coder: NSCoder) {
    super.init(coder: coder)
  }

  @IBInspectable var color: NSColor = NSColor.gray

  override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
    if isHighlighted {
//      debugPrint("highlightedFrame", cellFrame)
      drawOutline(cellFrame, selected: false)
      let internalSizeMultiplier = 0.6
      let inset = ((1 - internalSizeMultiplier) / 2) * Double(cellFrame.width)
      let size = Double(cellFrame.width) * internalSizeMultiplier
      let insideCircle = NSRect(x: inset, y: inset, width: size, height: size)
      let bpath = NSBezierPath(ovalIn: insideCircle)
      color.set()
      bpath.fill()
    } else {
//      debugPrint("otherFrame", state == NSOnState, cellFrame)
      drawOutline(cellFrame, selected: state == NSOnState)
    }
  }

  internal func drawOutline(_ rect: NSRect, selected: Bool) {
    let newRect = NSRect(x: 1, y: 1, width: rect.width - 2, height: rect.height - 2)
    let bpath = NSBezierPath(ovalIn: newRect)
    self.controlView?.layer?.backgroundColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0)

    color.set()
    bpath.lineWidth = 1
    bpath.stroke()

    if selected {
      bpath.fill()
    }
  }
}
