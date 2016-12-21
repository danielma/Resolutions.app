//
//  RequestPoller.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/20/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import PromiseKit
import PMKAlamofire

typealias Requestor = (Date) -> DataRequest

fileprivate func defaultCallback(_ value: JSON) { }

class RequestPoller {
  static let defaultInterval = 60

  let request: Requestor
  var pollInterval: Int
  var running = false
  var callback: (JSON) -> Void = defaultCallback
  var cancelNext = false
  var lastRequest: Date

  convenience init(request: @escaping Requestor) {
    self.init(pollInterval: RequestPoller.defaultInterval, request: request)
  }

  init(pollInterval: Int, request: @escaping Requestor) {
    self.pollInterval = pollInterval
    self.request = request
    self.lastRequest = Date(timeIntervalSince1970: TimeInterval(0))
  }

  func map(_ callback: @escaping (JSON) -> Void) -> RequestPoller {
    self.callback = callback

    return self
  }

  @discardableResult
  func start() -> RequestPoller {
    running = true

    iteration()

    return self
  }

  func forceRequest() {
    print("force request")
    cancelNext = true

    iteration()
  }

  func stop() {
    print("stopping poll")
    running = false
  }

  internal func enqueueNextIteration() {
    _ = after(interval: TimeInterval(self.pollInterval)).then { _ -> Void in
      if self.cancelNext {
        print("cancelled")
        self.cancelNext = false
        return
      }

      if self.running { self.iteration() }
    }
  }

  internal func iteration() {
    _ = request(self.lastRequest)
      .response()
      .then { (request, response, data) -> Void in
        self.updateIntervalFromResponse(response)
        self.enqueueNextIteration()
        if (self.shouldExecuteCallback(request: request, response: response, data: data)) {
          self.callback(JSON(data: data))
        }
    }

    lastRequest = Date()
  }

  internal func updateIntervalFromResponse(_ response: HTTPURLResponse) {
  }

  internal func shouldExecuteCallback(request: URLRequest, response: HTTPURLResponse, data: Data) -> Bool {
    return true
  }
}
