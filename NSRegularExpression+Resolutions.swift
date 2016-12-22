//
//  NSRegularExpression+Resolutions.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/21/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Foundation

extension NSRegularExpression {
  func hasMatch(_ string: String, options: NSRegularExpression.MatchingOptions = NSRegularExpression.MatchingOptions()) -> Bool {
    let range = NSMakeRange(0, string.characters.count)
    return firstMatch(in: string, options: options, range: range) != nil
  }
}
