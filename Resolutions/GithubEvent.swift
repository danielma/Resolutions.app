//
//  GithubEvent.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/5/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import Foundation
import SwiftyJSON

class GithubEvent: NSObject {
  let source: JSON
  let eventType: EventType

  enum EventType: String {
    case CommitCommentEvent
    case CreateEvent
    case DeleteEvent
    case DeploymentEvent
    case DeploymentStatusEvent
    case DownloadEvent
    case FollowEvent
    case ForkEvent
    case ForkApplyEvent
    case GistEvent
    case GollumEvent
    case IssueCommentEvent
    case IssuesEvent
    case LabelEvent
    case MemberEvent
    case MembershipEvent
    case MilestoneEvent
    case OrganizationEvent
    case OrgBlockEvent
    case PageBuildEvent
    case ProjectCardEvent
    case ProjectColumnEvent
    case ProjectEvent
    case PublicEvent
    case PullRequestEvent
    case PullRequestReviewEvent
    case PullRequestReviewCommentEvent
    case PushEvent
    case ReleaseEvent
    case RepositoryEvent
    case StatusEvent
    case TeamEvent
    case TeamAddEvent
    case WatchEvent
  }

  init(_ source: JSON) {
    self.source = source
    self.eventType = EventType.init(rawValue: source["type"].stringValue)!
  }

  var id: Int {
    return Int(source["id"].stringValue)!
  }

  var actor: JSON {
    return source["actor"]
  }

  var repo: JSON {
    return source["repo"]
  }

  var payload: JSON {
    return source["payload"]
  }

  var createdAt: Date {
    return jsonDateToDate(source["created_at"].stringValue)!
  }

  var issueIdentifier: String? {
    switch eventType {
    case .IssueCommentEvent:
      return payload["issue", "url"].string
    case .PullRequestEvent:
      return payload["pull_request", "issue_url"].string
    case .PullRequestReviewCommentEvent:
      return payload["pull_request", "issue_url"].string
    default:
      debugPrint("can't find issue identifier for \(self)")
      return nil
    }
  }

  lazy var afterResolutionUpdatedAt: Bool = {
    if let resolution = self.resolution {
      return !resolution.completed && resolution.updateDate!.compare(self.createdAt) == .orderedAscending
    }

    return false
  }()
  
  lazy var resolution: ResolutionMO? = {
    if let id = self.issueIdentifier {
      return ResolutionMO.fetchBy(remoteIdentifier: id)
    }

    return nil
  }()
}

class GithubPullRequestEvent: GithubEvent {
  enum ActionType: String {
    case assigned
    case unassigned
    case reviewRequested = "review_requested"
    case reviewRequestRemoved = "review_request_removed"
    case labeled
    case unlabeled
    case opened
    case edited
    case closed
    case reopened
  }
  
  var action: ActionType {
    return ActionType(rawValue: payload["action"].stringValue)!
  }
}

func jsonDateToDate(_ jsonDate: String?) -> Date? {
  guard let jsonDate = jsonDate else { return nil }

  let dateFormatter = DateFormatter()
  dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
  return dateFormatter.date(from: jsonDate)
}
