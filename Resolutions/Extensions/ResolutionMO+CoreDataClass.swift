//
//  ResolutionMO+CoreDataClass.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/3/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import Cocoa
import CoreData
import SwiftyJSON
import PromiseKit

@objc(ResolutionMO)
public class ResolutionMO: NSManagedObject {
  enum Status: String {
    case open
    case closed
    case merged
  }

  var status: Status? {
    get {
      return Status(rawValue: statusString ?? "")
    }
    set {
      statusString = newValue?.rawValue
    }
  }
  
  static func fromGithubEvent(_ event: GithubEvent, context: NSManagedObjectContext) -> ResolutionMO? {
    guard let payloadEvent = event.payloadEvent else {
      debugPrint("Can't create resolutionMO from github event \(event)")
      return nil
    }
    
    let repo = GithubRepoMO.fromGithubEvent(event, context: context)
    let remoteIdentifier = payloadEvent.issueIdentifier
    let resolution: ResolutionMO

    if let existingResolution = ResolutionMO.fetchBy(remoteIdentifier: remoteIdentifier, context: context) {
      resolution = existingResolution
    } else {
      resolution = ResolutionMO(context: context)
      resolution.remoteIdentifier = remoteIdentifier
      resolution.repo = repo
    }

    resolution.name = payloadEvent.issueName
    resolution.updateDate = event.createdAt as NSDate

    return resolution
  }

  static func fromGithubNotification(_ notification: GithubNotification, context: NSManagedObjectContext) -> ResolutionMO? {

    let repo = GithubRepoMO.fromGithubNotification(notification, context: context)
    let remoteIdentifier = notification.issueIdentifier
    let resolution: ResolutionMO

    if let existingResolution = ResolutionMO.fetchBy(remoteIdentifier: remoteIdentifier, context: context) {
      resolution = existingResolution
    } else {
      resolution = ResolutionMO(context: context)
      resolution.remoteIdentifier = remoteIdentifier
      resolution.repo = repo
    }

    resolution.name = notification.subjectTitle
    resolution.updateDate = notification.updatedAt as NSDate

    return resolution
  }

  static func fetchBy(remoteIdentifier: String, context: NSManagedObjectContext? = nil) -> ResolutionMO? {
    let moc: NSManagedObjectContext

    if let context = context {
      moc = context
    } else {
      moc = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
    }

    let resolutionFetch: NSFetchRequest<ResolutionMO> = ResolutionMO.fetchRequest()
    resolutionFetch.predicate = NSPredicate(format: "remoteIdentifier == %@", remoteIdentifier)

    do {
      let fetched = try moc.fetch(resolutionFetch)
      return fetched.first
    } catch {
      fatalError("failed to fetch resolution with remoteIdentifier \(remoteIdentifier)")
    }
  }

  public var completed: Bool {
    get {
      if let completedDate = completedDate {
        return (completedDate as Date) <= Date()
      }

      return false
    }
    set {
      updateDate = NSDate()

      if (newValue) {
        completedDate = NSDate()
      } else {
        completedDate = nil
      }
    }
  }

  func completeAt(_ date: NSDate?) {
    completedDate = date
    updateDate = date ?? NSDate()
  }

  var isRefreshing = false
  var refreshCanComplete = false
  func refreshFromGithub(canComplete: Bool) -> Promise<ResolutionMO> {
    refreshCanComplete = refreshCanComplete || canComplete
    
    guard !isRefreshing else {
      return Promise(error: ResolutionError.AlreadyRefreshingResolution(self))
    }
    
    isRefreshing = true

    return when(fulfilled: refreshIssueFromGithub().asVoid(), refreshStatusFromGithub().asVoid(), refreshLabelsFromGithub().asVoid())
      .then { _, _, _ in self }
      .always {
        self.isRefreshing = false
        self.refreshCanComplete = false
      }
  }

  private func refreshIssueFromGithub() -> Promise<GithubIssue> {
    return issuePromise
      .then { issue in
        self.url = issue.htmlUrl

        if self.refreshCanComplete {
          self.completeAt(issue.state == .closed ? issue.updatedAt as NSDate : nil)
        } else {
          self.updateDate = issue.updatedAt as NSDate
        }

        return Promise(value: issue)
      }
  }

  private func refreshStatusFromGithub() -> Promise<Status> {
    return statusPromise.then { status in
      self.status = status
      return Promise(value: status)
    }
  }

  private func refreshLabelsFromGithub() -> Promise<[LabelMO]> {
    return issuePromise
      .then { issue in
        issue.labels.map { LabelMO.fromGithubLabel($0, context: self.managedObjectContext!) }
    }
  }

  lazy var issuePromise: Promise<GithubIssue> = {
    if let remoteIdentifier = self.remoteIdentifier {
      return GithubAPIClient.sharedInstance.issue(fromAbsoluteURL: remoteIdentifier)
    }

    return Promise(error: ResolutionError.MissingRemoteIdentifier(self))
  }()

  lazy var statusPromise: Promise<Status> = {
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

  public var touchDate: NSDate? {
    guard let updateDate = updateDate else { return completedDate }
    guard let completedDate = completedDate else { return updateDate }

    return (updateDate as Date) > (completedDate as Date) ? updateDate : completedDate
  }

  enum ResolutionError: Error {
    case MissingRemoteIdentifier(ResolutionMO)
    case AlreadyRefreshingResolution(ResolutionMO)
  }
}
