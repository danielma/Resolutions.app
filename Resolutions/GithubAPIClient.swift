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

typealias Params = Dictionary<String, String>

class GithubRequestPoller: RequestPoller {
  override internal func updateIntervalFromResponse(_ response: HTTPURLResponse) {
    print("updating interval from response")
    if let responsePollInterval = response.allHeaderFields["X-Poll-Interval"] as? String {
      pollInterval = Int(responsePollInterval) ?? pollInterval
      print("updated to \(pollInterval)")
    }
  }
}

class GithubAPIClient {
  static let sharedInstance = GithubAPIClient()

  let baseUrl = "https://api.github.com/"

  private var token: String {
    return UserDefaults.standard.value(forKey: "githubToken") as! String
  }

  private var username: String {
    return UserDefaults.standard.value(forKey: "githubUsername") as! String
  }

  func notifications() -> Promise<JSON> {
    return notifications(all: false)
  }
  
  func notifications(all: Bool) -> Promise<JSON> {
    let allParam = all ? "true" : "false"
    return get("notifications", parameters: ["all": allParam])
  }

  func pollNotifications() -> RequestPoller {
    return poll("notifications", parameters: [:])
  }

  func userEvents() -> Promise<JSON> {
    return get("users/\(username)/events")
  }

  private func poll(_ url: String, parameters: Params) -> RequestPoller {
    return GithubRequestPoller { return self.request(url, parameters: parameters) }
  }

  private func get(_ url: String) -> Promise<JSON> {
    return get(url, parameters: [:])
  }

  private func request(_ url: String, parameters: Params) -> DataRequest {
    var headers: HTTPHeaders = [:]

    if let authorizationHeader = Request.authorizationHeader(user: username, password: token) {
      headers[authorizationHeader.key] = authorizationHeader.value
    }

    return Alamofire.request("\(baseUrl)\(url)", parameters: parameters, headers: headers).validate()
  }

  private func get(_ url: String, parameters: Params) -> Promise<JSON> {
    return request(url, parameters: parameters)
      .responseJSON()
      .then { json in
        return Promise(value: JSON(json))
      }.catch { error in
        debugPrint(error)
      }
  }
}
