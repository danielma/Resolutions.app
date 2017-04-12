//
//  GithubIssue.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/10/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import Foundation
import SwiftyJSON
import PromiseKit

class GithubIssue: JSONBacked {
  lazy var state: GithubIssueState = {
    return GithubIssueState(rawValue: self.source["state"].stringValue)!
  }()

  lazy var pullRequestPromise: Promise<GithubPullRequest>? = {
    let pullRequest = self.source["pull_request"]

    if pullRequest.exists() {
      return GithubAPIClient.sharedInstance.pullRequest(fromAbsoluteURL: pullRequest["url"].string!)
    }

    return nil
  }()

  lazy var htmlUrl: String = {
    return self.source["html_url"].string!
  }()

  lazy var updatedAt: Date = {
    return jsonDateToDate(self.source["updated_at"].stringValue)!
  }()

  lazy var labels: [GithubLabel] = {
    return self.source["labels"].arrayValue.map { GithubLabel($0) }
  }()
}

class GithubPullRequest: JSONBacked {
  lazy var state: GithubIssueState = {
    if self.merged { return GithubIssueState.merged }
    
    return GithubIssueState(rawValue: self.source["state"].stringValue)!
  }()

  lazy var merged: Bool = {
    return self.source["merged"].boolValue
  }()
}
