//
//  ResolutionMO+Resolutions.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/3/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import Cocoa
import SwiftyJSON

struct GithubRepo {
  let source: JSON
  let name: String
  let url: String
  let remoteIdentifier: String

  init(_ source: JSON, name: String? = nil, url: String? = nil, remoteIdentifier: String? = nil) {
    self.source = source
    self.name = name ?? source["name"].string!
    self.url = url ?? source["html_url"].string!
    self.remoteIdentifier = remoteIdentifier ?? source["url"].string!
  }
}

extension GithubRepoMO {
  static func fetchBy(name: String, context: NSManagedObjectContext) -> GithubRepoMO? {
    let resolutionFetch: NSFetchRequest<GithubRepoMO> = GithubRepoMO.fetchRequest()
    resolutionFetch.predicate = NSPredicate(format: "name == %@", name)

    do {
      let fetched = try context.fetch(resolutionFetch)
      return fetched.first
    } catch {
      fatalError("failed to fetch resolution with remoteIdentifier \(name)")
    }
  }

  static func fromGithubEvent(_ event: GithubEvent, context: NSManagedObjectContext) -> GithubRepoMO {
    let repo: GithubRepoMO

    if let existingRepo = GithubRepoMO.fetchBy(name: event.repo.name, context: context) {
      repo = existingRepo
    } else {
      repo = GithubRepoMO(context: context)
      repo.name = event.repo.name
      repo.url = event.repo.url
      repo.remoteIdentifier = event.repo.remoteIdentifier
    }

    return repo
  }

  static func fromGithubNotification(_ notification: GithubNotification, context: NSManagedObjectContext) -> GithubRepoMO {
    let repo: GithubRepoMO

    if let existingRepo = GithubRepoMO.fetchBy(name: notification.repo.name, context: context) {
      repo = existingRepo
    } else {
      repo = GithubRepoMO(context: context)
      repo.name = notification.repo.name
      repo.url = notification.repo.url
      repo.remoteIdentifier = notification.repo.remoteIdentifier
    }

    return repo
  }
}
