//
//  NutellaTests.swift
//  NutellaTests
//
//  Created by Gianluca Venturini on 13/01/15.
//  Copyright (c) 2015 Gianluca Venturini. All rights reserved.
//

import Cocoa
import XCTest

import Nutella

class NutellaTests: XCTestCase, NutellaDelegate {
    
    var nutella: Nutella?
    
    var expectation: XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        nutella = Nutella(host: "127.0.0.1", actorName: "test_actor", runId:"test")
        nutella?.delegate = self
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testPublish() {
        nutella?.net.publish("test/channel", message: ["ciao":"mondo"])
    }
    
    func testRequestSync() {
        nutella?.net.syncRequest("test/request", message: ["test":"test"], requestName: "test_request")
        
        expectation = expectationWithDescription("Response back")
        
        waitForExpectationsWithTimeout(300, handler: nil)
    }
    
    // NutellaDelegate
    
    func responseReceived(channelName: String, requestName: String?, response: String) {
        expectation?.fulfill()
    }
    
}