//
//  GithubPollerTests.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/23/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import XCTest
@testable import Resolutions
import GRDB

class GithubPollerTests: XCTestCase {

  override func setUp() {
    super.setUp()

    try! deleteDatabase()
    try! setupDatabase()
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  internal func loadJSON(_ key: String) -> Data {
    let jsonUrl = Bundle(for: type(of: self)).url(forResource: key, withExtension: "json")

    return try! Data(contentsOf: jsonUrl!)
  }

  internal func handleResponse(_ poller: RequestPoller, _ jsonKey: String) {
    let request = URLRequest(url: URL(string: "https://api.github.com/notifications")!)
    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
    let data = loadJSON(jsonKey)
    poller.handleRequestResponse(request: request, response: response, data: data)
  }

  let poller = GithubPoller(defaults: UserDefaults(suiteName: "githubPollerTests")!)

  func testIncomingNotifications() {
    handleResponse(poller.notificationsPoller, "notifications")

    dbQueue.inDatabase { (db) in
      let names = try! String.fetchAll(db, "SELECT name FROM resolutions")
      debugPrint(names)
      XCTAssert(names.contains("My Pull Request"))
    }
  }

  func testIssueCommentEventShouldCompleteNotification() {
    handleResponse(poller.notificationsPoller, "notifications")
    handleResponse(poller.eventsPoller, "issueCommentEvents")

    dbQueue.inDatabase { (db) in
      let names = try! String.fetchAll(db, "SELECT name FROM resolutions WHERE completedAt IS NOT NULL")
      debugPrint(names)
      XCTAssert(names.contains("My Pull Request"))
    }
  }

  func testMagicCommentEventShouldNotCompleteNotification() {
    poller.userDefaults.set(true, forKey: "githubUseMagicComments")
    poller.userDefaults.set("!!NOCLOSE", forKey: "githubMagicCommentString")
    
    handleResponse(poller.notificationsPoller, "notifications")
    handleResponse(poller.eventsPoller, "magicIssueCommentEvents")

    dbQueue.inDatabase { (db) in
      let names = try! String.fetchAll(db, "SELECT name FROM resolutions WHERE completedAt IS NOT NULL")
      XCTAssert(names.count == 0)
    }
  }

  func testMagicCommentEventShouldCompleteNotificationIfNotEnabled() {
    poller.userDefaults.set(false, forKey: "githubUseMagicComments")
    poller.userDefaults.set("!!NOCLOSE", forKey: "githubMagicCommentString")
    
    handleResponse(poller.notificationsPoller, "notifications")
    handleResponse(poller.eventsPoller, "magicIssueCommentEvents")

    dbQueue.inDatabase { (db) in
      let names = try! String.fetchAll(db, "SELECT name FROM resolutions WHERE completedAt IS NOT NULL")
      XCTAssert(names[0] == "My Pull Request")
    }
  }

  func testNonMagicCommentEventShouldCompleteNotification() {
    poller.userDefaults.set(true, forKey: "githubUseMagicComments")
    poller.userDefaults.set("!!MAGIC", forKey: "githubMagicCommentString")
    
    handleResponse(poller.notificationsPoller, "notifications")
    handleResponse(poller.eventsPoller, "magicIssueCommentEvents")

    dbQueue.inDatabase { (db) in
      let names = try! String.fetchAll(db, "SELECT name FROM resolutions WHERE completedAt IS NOT NULL")
      XCTAssert(names[0] == "My Pull Request")
    }
  }

  func testIgnorePullRequestMergedEvent() {
    poller.userDefaults.set(["pullRequestMerged": false], forKey: GithubPoller.ignoredEventsKey)

    handleResponse(poller.eventsPoller, "pullRequestMergedEvents")

    dbQueue.inDatabase { db in
      let names = try! String.fetchAll(db, "SELECT name FROM resolutions WHERE ")
    }
  }
}
