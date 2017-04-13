//
//  LabelStackView.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/12/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import Foundation
import Cocoa

class LabelContainer: NSView {
  var _labels: Set<LabelMO>?

  @objc
  public var labels: Set<LabelMO>? {
    set {
      _labels = newValue
      self.newLabels()
    }
    get {
      return _labels
    }
  }

  private func newLabels() {
    guard let labels = labels else {
      subviews.forEach { $0.removeFromSuperview() }
      return
    }

    let existingViewsCount = subviews.count
    let viewsToRemove = existingViewsCount - labels.count

    for (index, label) in labels.enumerated() {
      if existingViewsCount <= index {
        let frame = NSMakeRect(0, 0, 20, 20)
        let sub = LabelView(frame: frame)
        sub.label = label
        addSubview(sub)

        if subviews.count > 1 {
          sub.buildConstraintsToPreviousView(self, previous: subviews[index - 1])
        } else {
          sub.buildConstraintsToStackView(self)
        }
      } else {
        (subviews[index] as! LabelView).label = label
      }
    }

    if viewsToRemove > 0 {
      for _ in 1...viewsToRemove {
        if let view = subviews.last {
          view.removeFromSuperview()
        }
      }
    }
  }
}

class LabelView: NSView {
  var _label: LabelMO?
  var label: LabelMO? {
    get { return _label }
    set {
      _label = newValue
      labelUpdated()
    }
  }

  override init(frame: NSRect) {
    super.init(frame: frame)

    commonInit()

    let sub = LabelTextField(frame: frame)
    addSubview(sub)
    sub.buildConstraintsToPillView(self)
  }

  required init?(coder: NSCoder) {
    fatalError("No init from coder")
  }

//  override func viewWillDraw() {
//    if let textField = subviews.first as? LabelTextField {
//      var newSize = frame.size
//      newSize.width = textField.frame.size.width + 10
//      setFrameSize(newSize)
//    }
//
//    super.viewWillDraw()
//  }
//
  private func labelUpdated() {
    if let textField = subviews.first as? LabelTextField {
      textField.stringValue = label?.name ?? "WUUT"
      textField.sizeToFit()
      widthAnchor.constraint(equalToConstant: textField.frame.size.width + 10).isActive = true

      if let color = label?.getNSColor() {
        textField.textColor = color.isLight() ? NSColor.black : NSColor.white
      }
      textField.needsUpdateConstraints = true
    }
  }

  private func commonInit() {
    wantsLayer = true
    layer?.cornerRadius = 9
    layer?.masksToBounds = true
    translatesAutoresizingMaskIntoConstraints = false
//    autoresizesSubviews = true
  }

  override func draw(_ dirtyRect: NSRect) {
    if let color = label?.getNSColor() {
      color.setFill()
      NSRectFill(dirtyRect)
    }

    super.draw(dirtyRect)
  }
  
  func buildConstraintsToStackView(_ pillView: NSView) {
    centerYAnchor.constraint(equalTo: pillView.centerYAnchor).isActive = true
    leadingAnchor.constraint(equalTo: pillView.leadingAnchor, constant: 3).isActive = true
    heightAnchor.constraint(equalToConstant: 18).isActive = true
  }

  func buildConstraintsToPreviousView(_ pillView: NSView, previous: NSView) {
    centerYAnchor.constraint(equalTo: pillView.centerYAnchor).isActive = true
    leadingAnchor.constraint(equalTo: previous.trailingAnchor, constant: 8).isActive = true
    heightAnchor.constraint(equalToConstant: 18).isActive = true
  }
}

class LabelTextField: NSTextField {
  override init(frame: NSRect) {
    super.init(frame: frame)

    commonInit()
  }

  required init?(coder: NSCoder) {
    fatalError("No init from coder")
  }

  private func commonInit() {
    isBezeled = false
    isBordered = false
    drawsBackground = false
    isEditable = false
    isSelectable = false
    focusRingType = .none
    alignment = .center
//    lineBreakMode = .byWordWrapping
    font = NSFont.systemFont(ofSize: NSFont.labelFontSize() - 1, weight: 0.4)
    translatesAutoresizingMaskIntoConstraints = false
  }

  func buildConstraintsToPillView(_ pillView: LabelView) {
    centerYAnchor.constraint(equalTo: pillView.centerYAnchor, constant: 0).isActive = true
    centerXAnchor.constraint(equalTo: pillView.centerXAnchor).isActive = true
  }
}
