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
    if let responsePollInterval = response.allHeaderFields["X-Poll-Interval"] as? String {
      pollInterval = Int(responsePollInterval) ?? pollInterval
    }
  }

  override internal func shouldExecuteCallback(request: URLRequest, response: HTTPURLResponse, data: Data) -> Bool {
    if let status = response.allHeaderFields["Status"] as? String, status == "304 Not Modified" {
      return false
    }

    return true
  }
}

func dateToHttp(_ date: Date) -> String {
  let locale = Locale(identifier: "en_US")
  let timeZone = TimeZone(identifier: "GMT")
  let dateFormatter = DateFormatter()
  dateFormatter.locale = locale
  dateFormatter.timeZone = timeZone
  dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"

  return dateFormatter.string(from: date)
}

class GithubAPIClient {
  static let sharedInstance = GithubAPIClient()

  let baseUrl = "https://api.github.com/"

  lazy var afSessionManager: SessionManager = {
    let configuration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    return SessionManager(configuration: configuration)
  }()

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
    return poll("notifications", parameters: ["all": "true"])
  }

  func userEvents() -> Promise<JSON> {
    return get("users/\(username)/events")
  }

  func pollUserEvents() -> RequestPoller {
    return poll("users/\(username)/events")
  }

  internal func poll(_ url: String) -> RequestPoller {
    return poll(url, parameters: [:])
  }

  private func poll(_ url: String, parameters: Params) -> RequestPoller {
    return GithubRequestPoller { lastRequest in
      return self.request(url, parameters: parameters, headers: ["If-Modified-Since": dateToHttp(lastRequest)])
    }
  }

  private func get(_ url: String) -> Promise<JSON> {
    return get(url, parameters: [:])
  }

  internal func request(_ url: String, parameters: Params) -> DataRequest {
    return request(url, parameters: parameters, headers: [:])
  }

  private func request(_ url: String, parameters: Params, headers: HTTPHeaders) -> DataRequest {
    var headers = headers

    if let authorizationHeader = Request.authorizationHeader(user: username, password: token) {
      headers[authorizationHeader.key] = authorizationHeader.value
    }

    return afSessionManager
      .request("\(baseUrl)\(url)", parameters: parameters, headers: headers)
      .validate(statusCode: [200, 304])
      .validate(contentType: ["application/json"])
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
