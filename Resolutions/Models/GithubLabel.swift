//
//  GithubLabel.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/11/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreData

class GithubLabel: JSONBacked {
  lazy var url: String = {
    return self.source["url"].string!
  }()

  lazy var name: String = {
    return self.source["name"].string!
  }()

  lazy var color: String = {
    return self.source["color"].string!
  }()
}

extension LabelMO {
  static func fetchBy(remoteIdentifier: String, context: NSManagedObjectContext) -> LabelMO? {
    let fetch: NSFetchRequest<LabelMO> = LabelMO.fetchRequest()
    fetch.predicate = NSPredicate(format: "remoteIdentifier == %@", remoteIdentifier)

    do {
      let fetched = try context.fetch(fetch)
      return fetched.first
    } catch {
      fatalError("Failed to fetch label with remoteIdentifier \(remoteIdentifier)")
    }
  }

  static func fromGithubLabel(_ ghl: GithubLabel, context: NSManagedObjectContext) -> LabelMO {
    let label: LabelMO

    if let existingLabel = LabelMO.fetchBy(remoteIdentifier: ghl.url, context: context) {
      label = existingLabel
    } else {
      label = LabelMO(context: context)
      label.remoteIdentifier = ghl.url
    }

    label.name = ghl.name
    label.color = ghl.color

    return label
  }
}
