//
//  GithubActor.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/7/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import Foundation
import SwiftyJSON

class GithubActor {
  let source: JSON

  init(_ source: JSON) {
    self.source = source
  }

  var login: String {
    return source["login"].string!
  }

  var isCurrentUser: Bool {
    return GithubAPIClient.sharedInstance.username == login
  }
}
