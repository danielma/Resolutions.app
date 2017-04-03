//
//  Resolution.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/19/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Foundation
import SwiftyJSON

class Resolution {
  static let githubIssueRegex = try! NSRegularExpression(
    pattern: "api\\.github\\.com/repos/([^/]+)/([^/]+)/issues/(\\w+)",
    options: .caseInsensitive
  )
  
  enum Kind {
    case GithubIssue
    case Unknown
  }

  var completedAt: Date?
  var remoteIdentifier: String
  var name: String
  var grouping: String?

  init(name: String, remoteIdentifier: String, completedAt: Date? = nil, grouping: String? = nil) {
    self.name = name
    self.remoteIdentifier = remoteIdentifier
    self.completedAt = completedAt
    self.grouping = grouping
  }

  var completed: Bool {
    if let completedAt = completedAt {
      return completedAt <= Date()
    }

    return false
  }

  var kind: Kind {
    switch true {
    case Resolution.githubIssueRegex.hasMatch(remoteIdentifier):
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
    switch kind {
    case .GithubIssue:
      let range = NSMakeRange(0, remoteIdentifier.characters.count)
      return Resolution.githubIssueRegex.stringByReplacingMatches(
        in: remoteIdentifier,
        options: NSRegularExpression.MatchingOptions(),
        range: range,
        withTemplate: "github.com/$1/$2/issues/$3"
      )
    default:
      return nil
    }
  }
}

fileprivate func cleanGithubNotificationRemoteIdentifier(_ identifier: String) -> String {
  let githubPullRequestRegex = try! NSRegularExpression(
    pattern: "api\\.github\\.com/repos/([^/]+)/([^/]+)/pulls/(\\w+)",
    options: .caseInsensitive
  )

  if githubPullRequestRegex.hasMatch(identifier) {
    return githubPullRequestRegex.stringByReplacingMatches(
      in: identifier,
      options: NSRegularExpression.MatchingOptions(),
      range: NSMakeRange(0, identifier.characters.count),
      withTemplate: "api.github.com/repos/$1/$2/issues/$3"
    )
  }

  return identifier
}

extension Resolution {
  convenience init(fromGithubNotification notification: JSON) {
    let name = notification["subject", "title"].stringValue
    let remoteIdentifier = cleanGithubNotificationRemoteIdentifier(notification["subject", "url"].stringValue)
    let grouping = notification["repository", "full_name"].string
    
    self.init(name: name, remoteIdentifier: remoteIdentifier, grouping: grouping)
  }
}
