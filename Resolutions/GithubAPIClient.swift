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

class GithubRequestPoller: RequestPoller<GithubEvent> {
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

  lazy var afSessionManager: SessionManager = {
    let configuration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
    configuration.requestCachePolicy = .reloadRevalidatingCacheData
    return SessionManager(configuration: configuration)
  }()

  private var token: String {
    return (UserDefaults.standard.value(forKey: "githubToken") as? String) ?? ""
  }

  private var username: String {
    return (UserDefaults.standard.value(forKey: "githubUsername") as? String) ?? ""
  }

  func notifications(all: Bool = true) -> Promise<JSON> {
    let allParam = all ? "true" : "false"
    return get("notifications", parameters: ["all": allParam])
  }

  func userEvents(page: Int = 1) -> Promise<[GithubEvent]> {
    return get("users/\(username)/events", parameters: ["per_page": "60", "page": String(page)])
      .then { events in events.arrayValue.map { GithubEvent($0) } }
  }

  internal func paginatedRequest<T>(
    initialData: [T] = [],
    page: Int = 1,
    shouldPerformNextRequest: @escaping ([T]) -> Bool,
    request: @escaping (Int) -> Promise<[T]>) -> Promise<[T]> {
    if shouldPerformNextRequest(initialData) {
      return request(page)
        .then { data -> Promise<[T]> in
          return self.paginatedRequest(
            initialData: initialData + data,
            page: page + 1,
            shouldPerformNextRequest: shouldPerformNextRequest,
            request: request
          )
        }
    } else {
      return Promise(value: initialData)
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

  func pollUserEvents(since: Int? = nil) -> GithubRequestPoller {
    debugPrint("polling since \(since)")
    return GithubRequestPoller(performRequest: { lastData in
      let usefulSince: Int?

      if let lastData = lastData {
        usefulSince = lastData.first?.id ?? nil
      } else {
        usefulSince = since
      }

      return self.allUserEvents(since: usefulSince)
    })
  }

  private func request(_ url: String, parameters: Params = [:], headers: HTTPHeaders = [:]) -> DataRequest {
    var headers = headers

    if let authorizationHeader = Request.authorizationHeader(user: username, password: token) {
      headers[authorizationHeader.key] = authorizationHeader.value
    }

    debugPrint("request", url, parameters)

    let request = afSessionManager
      .request("\(baseUrl)\(url)", parameters: parameters, headers: headers)
      .validate(statusCode: [200])
      .validate(contentType: ["application/json"])

    request.response().then { (_, response, _) -> Void in
      debugPrint("response from \(response.url)")
      if let xPollInterval = response.allHeaderFields["X-Poll-Interval"] as? String,
        let asInt = Int(xPollInterval) {
        self.pollInterval = asInt
      }
    }
    
    return request
  }

  private func get(_ url: String, parameters: Params = [:]) -> Promise<JSON> {
    return request(url, parameters: parameters)
      .responseJSON()
      .then { json in
        return Promise(value: JSON(json))
      }.catch { error in
        debugPrint(error)
      }
  }
}
