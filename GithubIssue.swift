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
