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
  static let sharedInstance = GithubAPIClient(userDefaults: UserDefaults.standard)

  let baseUrl = "https://api.github.com/"
  let userDefaults: UserDefaults
  var pollInterval = 60
  var activeRequestCount = 0

  init(userDefaults: UserDefaults) {
    self.userDefaults = userDefaults
  }

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

  func repo(fromAbsoluteURL url: String) -> Promise<GithubRepo> {
    return absoluteGet(url).then { source in
      GithubRepo(source, name: source["full_name"].string!)
    }
  }

  static let notificationsLastAccessedKey = "notificationsLastAccessedAt"
  var notificationsLastAccessedDate: String? {
    get {
      if let access = userDefaults.value(forKey: GithubAPIClient.notificationsLastAccessedKey) as? String {
        return access
      } else {
        return nil
      }
    }
    set {
      userDefaults.set(newValue, forKey: GithubAPIClient.notificationsLastAccessedKey)
    }
  }
  func notifications(all: Bool = true, page: Int = 1, headers: HTTPHeaders?) -> Promise<GithubArrayResponse<GithubNotification>> {
    let allParam = all ? "true" : "false"
    return request("notifications", parameters: ["all": allParam, "page": String(page)], headers: headers, useCaching: false)
      .tap {
        if case let .fulfilled(info) = $0,
          let date = info.1.allHeaderFields["Date"] as? String {
          self.notificationsLastAccessedDate = date
        }
      }
      .then { (_, response, data) in
        GithubArrayResponse(response: response, elements: JSON(data: data).arrayValue.map { GithubNotification($0) })
      }
  }

  func allNotifications(headers: HTTPHeaders? = nil) -> Promise<[GithubNotification]> {
    return paginatedRequest(
      shouldPerformNextRequest: { _ in return true },
      request: { page in self.notifications(page: page, headers: headers) }
    )
  }

  func userEvents(page: Int = 1) -> Promise<GithubArrayResponse<GithubEvent>> {
    return request("users/\(username)/events", parameters: ["per_page": "60", "page": String(page)])
      .then { (_, response, data) in
        GithubArrayResponse(response: response, elements: JSON(data: data).arrayValue.map { GithubEvent($0) })
      }
  }

  func allUserEvents(since eventId: Int? = nil) -> Promise<[GithubEvent]> {
    debugPrint("allUserEvents since \(String(describing: eventId))")
    if let eventId = eventId {
      return paginatedRequest(
        shouldPerformNextRequest: { events in
          return !events.contains { $0.id < eventId }
        }
      ) { page in self.userEvents(page: page) }
        .then { events in Array(events.reversed().drop { $0.id <= eventId }) }
    } else {
      return userEvents().then { $0.elements }
    }
  }

  internal func paginatedRequest<T>(
    initialData: [T] = [],
    page: Int = 1,
    shouldPerformNextRequest: @escaping ([T]) -> Bool,
    request: @escaping (Int) -> Promise<GithubArrayResponse<T>>
  ) -> Promise<[T]> {
    if shouldPerformNextRequest(initialData) {
      return request(page)
        .then { data -> Promise<[T]> in
          if data.pageLinks?.next != nil {
            return self.paginatedRequest(
              initialData: initialData + data.elements,
              page: page + 1,
              shouldPerformNextRequest: shouldPerformNextRequest,
              request: request
            )
          } else {
            return Promise(value: initialData + data.elements)
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

    activeRequestCount += 1

    return after(interval: TimeInterval(activeRequestCount / 10))
      .then { _ -> RequestPromise in
        debugPrint("request", url, parameters, headers)
        return (useCaching ? self.cachingSessionManager : self.noCachingSessionManager)
          .request(url, parameters: parameters, headers: headers)
          .validate(contentType: ["application/json"])
          .response()
      }
      .then { info -> RequestPromise in
        let response = info.1
//        debugPrint("response from \(response.url?.absoluteString ?? "")", response.statusCode, response.allHeaderFields)
        debugPrint("response from \(response.url?.absoluteString ?? "")", response.statusCode)
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
        debugPrint("error in request", error)
      }
  }

  private func get(_ url: String, parameters: Params = [:]) -> Promise<JSON> {
    return absoluteGet("\(baseUrl)\(url)", parameters: parameters)
  }

  private func absoluteGet(_ url: String, parameters: Params = [:]) -> Promise<JSON> {
    return absoluteRequest(url, parameters: parameters)
      .then { info -> RequestPromise in
        let response = info.1

        if (200..<300).contains(response.statusCode) { return Promise(value: info) }

        debugPrint(JSON(data: info.2))
        throw AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: response.statusCode))
      }
      .then { (_, _, data) in JSON(data: data) }
      .catch { error in
        debugPrint("error in get", error)
      }
  }
}

class PageLinks {
  let linkHeader: String
  let links: [String:String]

  init?(_ response: HTTPURLResponse) {
    guard let lh = response.allHeaderFields["Link"] as? String else { return nil }

    linkHeader = lh
    links = linkHeader
      .components(separatedBy: ",")
      .reduce([:]) { result, element in
        var result = result
        let parts = element.trimmingCharacters(in: .whitespaces).components(separatedBy: ";")

        let wrappedUrl = parts[0]
        let start = wrappedUrl.index(wrappedUrl.startIndex, offsetBy: 1)
        let end = wrappedUrl.index(wrappedUrl.endIndex, offsetBy: -1)
        let url = wrappedUrl.substring(with: start..<end)

        let rel = parts[1].components(separatedBy: "\"")[1]

        result[rel] = url
        return result
    }
  }

  lazy var next: String? = {
    return self.links["next"]
  }()
  
  lazy var prev: String? = {
    return self.links["prev"]
  }()

  lazy var last: String? = {
    return self.links["last"]
  }()
  
  lazy var first: String? = {
    return self.links["first"]
  }()
}

class GithubArrayResponse<Element> {
  let elements: [Element]
  let response: HTTPURLResponse

  init(response: HTTPURLResponse, elements: [Element]) {
    self.response = response
    self.elements = elements
  }

  lazy var pageLinks: PageLinks? = {
    return PageLinks(self.response)
  }()
}
