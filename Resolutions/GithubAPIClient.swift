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

struct EventPollState {
  var lastEvent: Int
  var lastData: [GithubEvent]
}

class GithubRequestPoller<T>: RequestPoller<T> {
  override internal func updateIntervalAfterResponse() -> Int {
    return GithubAPIClient.sharedInstance.pollInterval
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
  var pollInterval = 60
  var activeRequestCount = 0

  lazy var cachingSessionManager: SessionManager = {
    let configuration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
    configuration.requestCachePolicy = .reloadRevalidatingCacheData
    return SessionManager(configuration: configuration)
  }()

  lazy var noCachingSessionManager: SessionManager = {
    let configuration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    return SessionManager(configuration: configuration)
  }()

  private var token: String {
    return (UserDefaults.standard.value(forKey: "githubToken") as? String) ?? ""
  }

  var username: String {
    return (UserDefaults.standard.value(forKey: "githubUsername") as? String) ?? ""
  }

  func issue(fromAbsoluteURL url: String) -> Promise<GithubIssue> {
    return absoluteGet(url).then { GithubIssue($0) }
  }

  func pullRequest(fromAbsoluteURL url: String) -> Promise<GithubPullRequest> {
    return absoluteGet(url).then { GithubPullRequest($0) }
  }

  var notificationsLastAccessedDate: String?
  func notifications(all: Bool = true, page: Int = 1, headers: HTTPHeaders?) -> Promise<[GithubNotification]> {
    let allParam = all ? "true" : "false"
    return request("notifications", parameters: ["all": allParam, "page": String(page)], headers: headers, useCaching: false)
      .then { (_, response, data) in
        if let date = response.allHeaderFields["Date"] as? String {
          self.notificationsLastAccessedDate = date
        }

        return Promise(value: JSON(data: data).arrayValue.map { GithubNotification($0) })
      }
  }

  func allNotifications(headers: HTTPHeaders? = nil) -> Promise<[GithubNotification]> {
    return paginatedRequest(
      shouldPerformNextRequest: { _ in return true },
      request: { page in self.notifications(page: page, headers: headers) }
    )
  }

  func userEvents(page: Int = 1) -> Promise<[GithubEvent]> {
    return get("users/\(username)/events", parameters: ["per_page": "60", "page": String(page)])
      .then { events in events.arrayValue.map { GithubEvent($0) } }
  }

  func receivedEvents(page: Int = 1) -> Promise<[GithubEvent]> {
    return get("users/\(username)/received_events", parameters: ["per_page": "60", "page": String(page)])
      .then { events in events.arrayValue.map { GithubEvent($0) } }
  }

  func allReceivedEvents(since eventId: Int? = nil) -> Promise<[GithubEvent]> {
    debugPrint("allReceivedEvents since \(eventId)")
    if let eventId = eventId {
      return paginatedRequest(
        shouldPerformNextRequest: { events in
          return !events.contains { $0.id < eventId }
        }
      ) { page in self.receivedEvents(page: page) }
        .then { events in Array(events.reversed().drop { $0.id <= eventId }) }
    } else {
      return receivedEvents()
    }
  }
  
  func allUserEvents(since eventId: Int? = nil) -> Promise<[GithubEvent]> {
    debugPrint("allUserEvents since \(eventId)")
    if let eventId = eventId {
      return paginatedRequest(
        shouldPerformNextRequest: { events in
          return !events.contains { $0.id < eventId }
        }
      ) { page in self.userEvents(page: page) }
        .then { events in Array(events.reversed().drop { $0.id <= eventId }) }
    } else {
      return userEvents()
    }
  }

  internal func paginatedRequest<T>(
    initialData: [T] = [],
    page: Int = 1,
    shouldPerformNextRequest: @escaping ([T]) -> Bool,
    request: @escaping (Int) -> Promise<[T]>) -> Promise<[T]> {
    if shouldPerformNextRequest(initialData) {
      return request(page)
        .then { data -> Promise<[T]> in
          if data.count > 0 {
            return self.paginatedRequest(
              initialData: initialData + data,
              page: page + 1,
              shouldPerformNextRequest: shouldPerformNextRequest,
              request: request
            )
          } else {
            return Promise(value: initialData)
          }
        }
    } else {
      return Promise(value: initialData)
    }
  }

  typealias RequestPromise = Promise<(URLRequest, HTTPURLResponse, Data)>
  private func request(_ url: String, parameters: Params = [:], headers: HTTPHeaders? = nil, useCaching: Bool = true) -> RequestPromise {
    return absoluteRequest("\(baseUrl)\(url)", parameters: parameters, headers: headers, useCaching: useCaching)
  }
  
  private func absoluteRequest(_ url: String, parameters: Params = [:], headers: HTTPHeaders? = nil, useCaching: Bool = true) -> RequestPromise {
    var headers = headers ?? [:]

    if let authorizationHeader = Request.authorizationHeader(user: username, password: token) {
      headers[authorizationHeader.key] = authorizationHeader.value
    }

    headers["Accept"] = "application/vnd.github.black-cat-preview+json"

    debugPrint("request", url, parameters, headers)

    activeRequestCount += 1

    return after(interval: TimeInterval(activeRequestCount > 0 ? 1 : 0))
      .then { _ -> RequestPromise in
        return (useCaching ? self.cachingSessionManager : self.noCachingSessionManager)
          .request(url, parameters: parameters, headers: headers)
          .validate(contentType: ["application/json"])
          .validate(statusCode: 200..<300)
          .response()
      }
      .then { info -> RequestPromise in
        let response = info.1
        debugPrint("response from \(response.url?.absoluteString ?? "")", response.statusCode, response.allHeaderFields)
        if let xPollInterval = response.allHeaderFields["X-Poll-Interval"] as? String,
          let asInt = Int(xPollInterval) {
          self.pollInterval = asInt
        }

        return Promise(value: info)
      }
      .always {
        self.activeRequestCount -= 1
      }
      .catch { error in
        if let alamofireError = error as? AFError, alamofireError.isResponseValidationError, alamofireError.responseCode == 304 {
          debugPrint("swallowing 304")
        } else {
          debugPrint("error in request", error)
      }
    }
  }

  private func get(_ url: String, parameters: Params = [:]) -> Promise<JSON> {
    return absoluteGet("\(baseUrl)\(url)", parameters: parameters)
  }

  private func absoluteGet(_ url: String, parameters: Params = [:]) -> Promise<JSON> {
    return absoluteRequest(url, parameters: parameters)
      .then { (_, _, data) in JSON(data: data) }
      .catch { error in
        debugPrint("error in get", error)
      }
  }
}
