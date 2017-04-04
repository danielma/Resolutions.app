//
//  ResolutionMO+Resolutions.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/3/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import Cocoa
import SwiftyJSON

extension GithubRepoMO {
  static func fetchBy(name: String) -> GithubRepoMO? {
    let moc = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
    let resolutionFetch: NSFetchRequest<GithubRepoMO> = GithubRepoMO.fetchRequest()
    resolutionFetch.predicate = NSPredicate(format: "name == %@", name)

    do {
      let fetched = try moc.fetch(resolutionFetch)
      return fetched.first
    } catch {
      fatalError("failed to fetch resolution with remoteIdentifier \(name)")
    }
  }
}
