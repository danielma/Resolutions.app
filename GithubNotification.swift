//
//  GithubNotification.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/3/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import SwiftyJSON
import PromiseKit
import CoreData

class GithubNotification {
  let source: JSON

  init(_ source: JSON) {
    self.source = source
  }

  lazy var id: Int = {
    return Int(self.source["id"].stringValue)!
  }()

  lazy var reason: NotificationReason = {
    return NotificationReason(rawValue: self.source["reason"].stringValue)!
  }()

  lazy var updatedAt: Date = {
    return jsonDateToDate(self.source["updated_at"].string)!
  }()

  var type: NotificationType {
    return NotificationType(rawValue: source["subject", "type"].stringValue) ?? NotificationType.unknown
  }

  lazy var issuePromise: Promise<GithubIssue> = {
    if self.type == .PullRequest || self.type == .Issue {
      return GithubAPIClient.sharedInstance.issue(fromAbsoluteURL: self.issueIdentifier)
    }

    return Promise(error: NotificationError.NoIssue(self.subjectUrl))
  }()

  lazy var statusPromise: Promise<ResolutionMO.Status> = {
    return self.issuePromise.then { issue in
      if let pullRequestPromise = issue.pullRequestPromise {
        return pullRequestPromise.then { pullRequest in
          return ResolutionMO.Status(rawValue: pullRequest.state.rawValue)!
        }
      } else {
        return Promise(value: ResolutionMO.Status(rawValue: issue.state.rawValue)!)
      }
    }
  }()

  lazy var htmlUrlPromise: Promise<String> = {
    return self.issuePromise.then { $0.htmlUrl }
  }()

  lazy var repo: GithubRepo = {
    let repository = self.source["repository"]
    return GithubRepo(repository, name: repository["full_name"].string!)
  }()

  lazy var issueNumber: Int? = {
    if let match = matches(for: "\\d+$", in: self.source["subject", "url"].stringValue).first {
      return Int(match)!
    }

    return nil
  }()

  private func getResolution(context: NSManagedObjectContext) -> ResolutionMO? {
    return ResolutionMO.fromGithubNotification(self, context: context)
  }

  func updateResolution(context: NSManagedObjectContext) -> Promise<Void> {
    return issuePromise
      .then { issue in
        guard let resolution = self.getResolution(context: context), let updateDate = resolution.updateDate else {
          debugPrint("unable to create resolution from \(self)")
          throw GithubNotification.NotificationError.NoResolution(issue)
        }

        resolution.url = issue.htmlUrl

        if (updateDate as Date) <= self.updatedAt {
          resolution.completeAt(issue.state == .closed ? self.updatedAt as NSDate : nil)
        }

        return self.statusPromise
          .then { status -> Void in
            resolution.status = status
          }
          .catch { error in debugPrint("couldn't set status", error) }
      }
      .catch { error in
        debugPrint("notification can't update resolution", error)
    }
  }

  var subjectUrl: String {
    return source["subject", "url"].stringValue
  }

  var subjectTitle: String {
    return source["subject", "title"].stringValue
  }

  var issueIdentifier: String {
    return cleanGithubNotificationRemoteIdentifier(subjectUrl)
  }

  enum NotificationReason: String {
    case assign
    case author
    case comment
    case invitation
    case manual
    case mention
    case stateChange = "state_change"
    case subscribed
    case teamMention = "team_mention"
  }

  enum NotificationType: String {
    case PullRequest
    case Issue
    case unknown
  }

  enum NotificationError: Error {
    case NoIssue(String)
    case NoResolution(GithubIssue)
  }
}

class GithubNotificationSubject {}

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

fileprivate func matches(for regex: String, in text: String) -> [String] {
  do {
    let regex = try NSRegularExpression(pattern: regex)
    let nsString = text as NSString
    let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
    return results.map { nsString.substring(with: $0.range)}
  } catch let error {
    fatalError("invalid regex: \(error.localizedDescription)")
  }
}
