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