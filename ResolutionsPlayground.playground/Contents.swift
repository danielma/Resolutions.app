//: Playground - noun: a place where people can play

import Cocoa

var str = "Hello, playground"

let date = Date()


let locale = Locale(identifier: "en_US")
let timeZone = TimeZone(identifier: "GMT")
let dateFormatter = DateFormatter()
dateFormatter.locale = locale //need locale for some iOS 9 verision, will not select correct default locale
dateFormatter.timeZone = timeZone
dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
dateFormatter.string(from: date)
Int.max
Int64.max

let testStr = "https://api.github.com/repos/ministrycentered/accounts/pulls/782"
//let regex = try! NSRegularExpression(pattern: "api\.github\.com/repos/(\w+)/(\w+)/pulls/(\w+)", options: .caseInsensitive)
let regex = try! NSRegularExpression(pattern: "api\\.github\\.com/repos/(\\w+)/(\\w+)/pulls/(\\w+)", options: .caseInsensitive)
let range = NSMakeRange(0, testStr.characters.count)


regex.stringByReplacingMatches(in: testStr, options: .withoutAnchoringBounds, range: range, withTemplate: "github.com/$1/$2/pull/$3")
