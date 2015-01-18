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
    
    
    func testPublish() {
        nutella?.net.subscribe("test/publish")
        nutella?.net.publish("test/publish", message: ["ciao":"mondo"])
        
        expectation = expectationWithDescription("Response back")
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testRequestSync() {
        nutella?.net.handleRequest("test/request1")
        nutella?.net.handleRequest("test/request2")
        nutella?.net.syncRequest("test/request1", message: ["test":"test"], requestName: "test_request1")
        nutella?.net.syncRequest("test/request2", message: ["test":"test"], requestName: "test_request2")
    
        expectation = expectationWithDescription("Response 1 back")
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    // NutellaDelegate
    
    var c = 0
    func responseReceived(channelName: String, requestName: String?, response: AnyObject) {
        if let status = response["response"] as? String {
            if status == "everything ok" {
                if( channelName == "test/request1" && requestName == "test_request1") {
                    c++
                }
                if( channelName == "test/request2" && requestName == "test_request2") {
                    c++
                }
            }
        }
        println(c)
        if( c == 2 ) {
            expectation?.fulfill()
        }
    }
    
    func requestReceived(channelName: String, request: AnyObject) -> AnyObject? {
        return ["response": "everything ok"]
    }
    
    func messageReceived(channel: String, message: AnyObject, from: String) {
        if channel == "test/publish" && from == "test_actor" {
            expectation?.fulfill()
        }
    }
    
}