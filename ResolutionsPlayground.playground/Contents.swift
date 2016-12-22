//: Playground - noun: a place where people can play

import Cocoa


enum Kind: String {
  case Dude
  case Girl
}

extension NSRegularExpression {
  func hasMatch(_ string: String, options: NSRegularExpression.MatchingOptions = NSRegularExpression.MatchingOptions()) -> Bool {
    let range = NSMakeRange(0, string.characters.count)
    return firstMatch(in: string, options: options, range: range) != nil
  }
}

let x = Kind(rawValue: "heeeey")
let b = Kind(rawValue: "Dude")


let githubIssueRegex = try! NSRegularExpression(pattern: "api\\.github\\.com/repos/(\\w+)/([\\w\\-]+)/issues/(\\w+)", options: .caseInsensitive)
let remoteIdentifier = "https://api.github.com/repos/sstur/react_rte/issues/156"

githubIssueRegex.hasMatch(remoteIdentifier)