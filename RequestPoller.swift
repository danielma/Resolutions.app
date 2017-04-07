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


let defaultInterval = 60

class RequestPoller<Element> {
  typealias Requestor<T> = ([T]?) -> Promise<[T]>
  typealias Callback<T> = ([T]) -> Void

  let performRequest: Requestor<Element>
  var pollInterval: Int
  var running = false
  var callback: Callback<Element>!
  var cancelNext = false
  var lastData: [Element]?

  init(pollInterval: Int = defaultInterval, performRequest: @escaping Requestor<Element>) {
    self.pollInterval = pollInterval
    self.performRequest = performRequest
  }

  @discardableResult
  func map(_ callback: @escaping (Callback<Element>)) -> RequestPoller {
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
        self.cancelNext = false
        return
      }

      if self.running { self.iteration() }
    }
  }

  internal func iteration() {
    _ = performRequest(self.lastData)
      .then { (data) -> Void in
        self.handleRequestData(data: data)
    }
  }

  internal func handleRequestData(data: [Element]) {
    lastData = data
    pollInterval = updateIntervalAfterResponse() ?? pollInterval
    enqueueNextIteration()
    callback(data)
  }

  internal func updateIntervalAfterResponse() -> Int? {
    return nil
  }
}
