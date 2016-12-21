//
//  Resolution.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/19/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Foundation
import GRDB

enum ResolutionType {
  case GithubIssue
  case GithubPullRequest
  case Unknown
}

class Resolution: AppRecord {
  override class var databaseTableName: String { return "resolutions" }

  static let githubPullRequestRegex = try! NSRegularExpression(pattern: "api\\.github\\.com/repos/(\\w+)/(\\w+)/pulls/(\\w+)", options: .caseInsensitive)
  static let githubIssueRegex = try! NSRegularExpression(pattern: "api\\.github\\.com/repos/(\\w+)/(\\w+)/issues/(\\w+)", options: .caseInsensitive)

  var completedAt: Date?
  var remoteIdentifier: String
  var name: String

  required init(row: Row) {
    completedAt = row.value(named: "completedAt")
    remoteIdentifier = row.value(named: "remoteIdentifier")
    name = row.value(named: "name")

    super.init(row: row)
  }

  init(name: String, remoteIdentifier: String, completedAt: Date?) {
    self.name = name
    self.remoteIdentifier = remoteIdentifier
    self.completedAt = completedAt
    super.init()
  }

  var completed: Bool {
    if let completedAt = completedAt {
      return completedAt <= Date()
    }

    return false
  }

  var remoteIdentifierRange: NSRange {
    return NSMakeRange(0, remoteIdentifier.characters.count)
  }

  var type: ResolutionType {
    let matchOptions = NSRegularExpression.MatchingOptions()

    switch true {
    case Resolution.githubPullRequestRegex.firstMatch(in: remoteIdentifier, options: matchOptions, range: remoteIdentifierRange) != nil:
      return .GithubPullRequest
    case Resolution.githubIssueRegex.firstMatch(in: remoteIdentifier, options: matchOptions, range: remoteIdentifierRange) != nil:
      return .GithubIssue
    default:
      return .Unknown
    }
  }

  var url: URL? {
    if let string = urlString {
      return URL(string: string)
    } else {
      return nil
    }
  }

  private var urlString: String? {
    switch type {
    case .GithubPullRequest:
      return Resolution.githubPullRequestRegex.stringByReplacingMatches(
        in: remoteIdentifier,
        options: NSRegularExpression.MatchingOptions(),
        range: remoteIdentifierRange,
        withTemplate: "github.com/$1/$2/pull/$3"
      )
    case .GithubIssue:
      return Resolution.githubIssueRegex.stringByReplacingMatches(
        in: remoteIdentifier,
        options: NSRegularExpression.MatchingOptions(),
        range: remoteIdentifierRange,
        withTemplate: "github.com/$1/$2/issues/$3"
      )
    default:
      return nil
    }
  }

  convenience init(name: String, remoteIdentifier: String) {
    self.init(name: name, remoteIdentifier: remoteIdentifier, completedAt: nil)
  }

  override var appRecordDictionary: [String : DatabaseValueConvertible?] {
    return [
      "completedAt": completedAt,
      "remoteIdentifier": remoteIdentifier,
      "name": name,
    ]
  }
}
