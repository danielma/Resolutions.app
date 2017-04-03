//
//  GithubNotification.swift
//  Resolutions
//
//  Created by Daniel Ma on 4/3/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import SwiftyJSON

class GithubNotification {
  let source: JSON

  init(_ source: JSON) {
    self.source = source
  }
}
