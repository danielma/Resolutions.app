//
//  GithubAPIClient.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/20/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import PromiseKit
import PMKAlamofire

class GithubAPIClient {
  static let sharedInstance = GithubAPIClient()

  let baseUrl = "https://api.github.com/"

  func notifications() -> Promise<JSON> {
    return notifications(all: false)
  }
  
  func notifications(all: Bool) -> Promise<JSON> {
    let allParam = all ? "true" : "false"
    return request("notifications", parameters: ["all": allParam])
  }

  func userEvents() -> Promise<JSON> {
    return request("users/\(username)/events")
  }

  private var token: String {
    return UserDefaults.standard.value(forKey: "githubToken") as! String
  }

  private var username: String {
    return UserDefaults.standard.value(forKey: "githubUsername") as! String
  }

  private func request(_ url: String) -> Promise<JSON> {
    return request(url, parameters: [:])
  }

  private func request(_ url: String, parameters: Dictionary<String, String>) -> Promise<JSON> {
    var headers: HTTPHeaders = [:]

    if let authorizationHeader = Request.authorizationHeader(user: username, password: token) {
      headers[authorizationHeader.key] = authorizationHeader.value
    }

    return Alamofire.request("\(baseUrl)\(url)", parameters: parameters, headers: headers)
      .validate()
      .responseJSON()
      .then { json in
        return Promise(value: JSON(json))
      }.catch { error in
        debugPrint(error)
      }
  }
}
