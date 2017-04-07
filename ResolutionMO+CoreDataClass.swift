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

@objc(ResolutionMO)
public class ResolutionMO: NSManagedObject {
  static func fromGithubEvent(_ event: GithubEvent) -> ResolutionMO? {
    let context = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext

    guard let payloadEvent = event.payloadEvent else {
      debugPrint("Can't create resolutionMO from github event \(event)")
      return nil
    }
//    let repoName = event.repo notification["repository", "full_name"].stringValue
    
    let repo = GithubRepoMO.fromGithubEvent(event)
    let remoteIdentifier = cleanGithubNotificationRemoteIdentifier(payloadEvent.issueIdentifier)
    let resolution: ResolutionMO

    if let existingResolution = ResolutionMO.fetchBy(remoteIdentifier: remoteIdentifier, context: context) {
      resolution = existingResolution
    } else {
      resolution = ResolutionMO(context: context)
      resolution.remoteIdentifier = cleanGithubNotificationRemoteIdentifier(payloadEvent.issueIdentifier)
      resolution.repo = repo
    }

    resolution.name = payloadEvent.issueName
    resolution.updateDate = NSDate()

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
