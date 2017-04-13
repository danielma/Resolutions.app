//: Playground - noun: a place where people can play

import Cocoa

let x = [1,2,3]

x[0]

func hexToNs(_ hex: String) -> NSColor {
  guard let hex = Int(hex, radix: 16) else {
    return NSColor.clear
  }

  let red = Double((hex >> 16 & 0xFF))
  let green = Double((hex >> 8 & 0xFF))
  let blue = Double((hex >> 0 & 0xFF))

  return NSColor(
    red: CGFloat(red / 255.0),
    green: CGFloat(green / 255.0),
    blue: CGFloat(blue / 255.0),
    alpha: 1
  )
}

hexToNs("CC9C00")
hexToNs("00FA00")