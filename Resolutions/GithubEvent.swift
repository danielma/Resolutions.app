//
//  GithubEvent.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/5/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import Foundation
import SwiftyJSON

class GithubEvent {
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

  lazy var actor: GithubActor = {
    return GithubActor(self.source["actor"])
  }()

  lazy var repo: GithubRepo = {
    return GithubRepo(self.source["repo"])
  }()

  var createdAt: Date {
    return jsonDateToDate(source["created_at"].stringValue)!
  }

  lazy var payloadEvent: GithubPayloadEventImplementation? = {
    switch self.eventType {
    case .PullRequestEvent:
      return GithubPullRequestEvent(self)
    case .PullRequestReviewCommentEvent:
      return GithubPullRequestReviewCommentEvent(self)
    case .IssuesEvent:
      return GithubIssuesEvent(self)
    case .IssueCommentEvent:
      return GithubIssueCommentEvent(self)
    default:
      return nil
    }
  }()

  var issueIdentifier: String? {
    if let event = payloadEvent {
      return event.issueIdentifier
    }

    debugPrint("can't find issue identifier for \(self)")
    return nil
  }

  func updateResolution() {
    if let event = payloadEvent {
      event.updateResolution()
    } else {
      debugPrint("no action for event type: \(eventType)")
    }
  }
}

enum GithubIssueState: String {
  case open
  case closed
  case merged
}

protocol GithubPayloadEventImplementation {
  var issueName: String { get }
  var issueIdentifier: String { get }
  var githubEvent: GithubEvent { get }
  func updateResolution() -> Void
}

extension GithubPayloadEventImplementation {
  var resolution: ResolutionMO? {
    return ResolutionMO.fetchBy(remoteIdentifier: self.issueIdentifier)
  }

  var afterResolutionUpdatedAt: Bool {
    if let resolution = self.resolution {
      if let updateDate = resolution.updateDate {
        return !resolution.completed && updateDate.compare(self.createdAt as Date) == .orderedAscending
      } else {
        return true
      }
    }

    return false
  }

  var createdAt: NSDate {
    return githubEvent.createdAt as NSDate
  }
}

class GithubPayloadEvent {
  let githubEvent: GithubEvent

  init(_ githubEvent: GithubEvent) {
    self.githubEvent = githubEvent
  }

  var payload: JSON {
    return githubEvent.source["payload"]
  }

  func createResolution() {
    _ = ResolutionMO.fromGithubEvent(githubEvent)
  }
  
  lazy var actor: GithubActor = {
    return self.githubEvent.actor
  }()
}

class GithubPullRequestEvent: GithubPayloadEvent, GithubPayloadEventImplementation {
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

  var state: GithubIssueState {
    if action == .closed && payload["pull_request", "merged"].boolValue {
      return .merged
    } else {
      return GithubIssueState(rawValue: payload["pull_request", "state"].stringValue)!
    }
  }

  var issueIdentifier: String {
    return payload["pull_request", "issue_url"].string!
  }

  var issueName: String {
    return payload["pull_request", "title"].string!
  }

  func updateResolution() {
    switch action {
    case .closed:
      if afterResolutionUpdatedAt {
        resolution!.completedDate = createdAt
      }
    default:
      if let resolution = resolution {
        if afterResolutionUpdatedAt {
          resolution.updateDate = createdAt
          resolution.completedDate = actor.isCurrentUser ? createdAt : nil
        }
      } else {
        createResolution()
      }
    }

    if let resolution = resolution {
      resolution.status = ResolutionMO.Status(rawValue: state.rawValue)!
    }
  }
}

class GithubIssuesEvent: GithubPayloadEvent, GithubPayloadEventImplementation {
  enum ActionType: String {
    case assigned
    case unassigned
    case labeled
    case unlabeled
    case opened
    case edited
    case milestoned
    case demilestoned
    case closed
    case reopened
  }

  var action: ActionType {
    return ActionType(rawValue: payload["action"].stringValue)!
  }

  var state: GithubIssueState {
    return GithubIssueState(rawValue: payload["issue", "state"].stringValue)!
  }

  var issueIdentifier: String {
    return payload["issue", "url"].string!
  }

  var issueName: String {
    return payload["issue", "title"].string!
  }

  func updateResolution() {
    switch action {
    case .closed:
      if afterResolutionUpdatedAt {
        resolution!.completedDate = createdAt
      }
    default:
      if let resolution = resolution {
        if afterResolutionUpdatedAt {
          resolution.updateDate = createdAt
          resolution.completedDate = actor.isCurrentUser ? createdAt : nil
        }
      } else {
        createResolution()
      }
    }

    if let resolution = resolution {
      resolution.status = ResolutionMO.Status(rawValue: state.rawValue)!
    }
  }
}

class GithubIssueCommentEvent: GithubPayloadEvent, GithubPayloadEventImplementation {
  enum ActionType: String {
    case created
    case edited
    case deleted
  }

  var action: ActionType {
    return ActionType(rawValue: payload["action"].stringValue)!
  }

  var issueIdentifier: String {
    return payload["issue", "url"].string!
  }

  var issueName: String {
    return payload["issue", "title"].string!
  }

  func updateResolution() {
    guard afterResolutionUpdatedAt else { return }

    resolution!.completedDate = createdAt
  }
}

class GithubPullRequestReviewCommentEvent: GithubPayloadEvent, GithubPayloadEventImplementation {
  enum ActionType: String {
    case created
    case edited
    case deleted
  }

  var action: ActionType {
    return ActionType(rawValue: payload["action"].stringValue)!
  }

  var issueIdentifier: String {
    return payload["pull_request", "issue_url"].string!
  }

  var issueName: String {
    return payload["pull_request", "title"].string!
  }

  func updateResolution() {
    guard afterResolutionUpdatedAt else { return }
    
//      if userDefaults.bool(forKey: "githubUseMagicComments") {
//          let magicValue = userDefaults.string(forKey: "githubMagicCommentString")
//          guard !event.commentIncludesMagicValue(magicValue) else { return }
//      }

    resolution!.completedDate = createdAt
  }
}

func jsonDateToDate(_ jsonDate: String?) -> Date? {
  guard let jsonDate = jsonDate else { return nil }

  let dateFormatter = DateFormatter()
  dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
  return dateFormatter.date(from: jsonDate)
}
