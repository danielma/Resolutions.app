//
//  ResolutionMO+CoreDataProperties.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/3/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import Foundation
import CoreData


extension ResolutionMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ResolutionMO> {
        return NSFetchRequest<ResolutionMO>(entityName: "Resolution")
    }

    @NSManaged public var completedDate: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var remoteIdentifier: String?
    @NSManaged public var updateDate: NSDate?
    @NSManaged public var repo: GithubRepoMO?
    @NSManaged public var statusString: String?
    @NSManaged public var url: String?
    @NSManaged public var labels: NSOrderedSet?
}
