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

class NutellaTests: XCTestCase, NutellaNetDelegate {
    
    var nutella: Nutella?
    
    var expectation: XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        nutella = Nutella(brokerHostname: "ltg.evl.uic.edu", runId: "test_run", componentId: "test_component")
        nutella?.resourceId = "test_resource"
        nutella?.netDelegate = self
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testPublishSubscribe() {
        responseCount = 1
        
        nutella?.net.subscribe("test/publish")
        nutella?.net.publish("test/publish", message: ["ciao":"mondo"])
        
        expectation = expectationWithDescription("testPublishSubscribe")
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testPublishSubscribeWildcard() {
        responseCount = 1
        
        nutella?.net.subscribe("test/#")
        nutella?.net.publish("test/publish", message: ["ciao":"mondo"])
        
        expectation = expectationWithDescription("testPublishSubscribeWildcard")
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testRequestResponse() {
        responseCount = 1
        
        nutella?.net.handleRequest("test/request1")
        nutella?.net.asyncRequest("test/request1", message: "message", requestName: "test_request1")
        
        expectation = expectationWithDescription("testRequestResponse")
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testMultipleRequestResponse() {
        responseCount = 2
        
        nutella?.net.handleRequest("test/request1")
        nutella?.net.asyncRequest("test/request1", message: "message", requestName: "test_request1")
        
        nutella?.net.handleRequest("test/request2")
        nutella?.net.asyncRequest("test/request2", message: "message", requestName: "test_request2")
        
        expectation = expectationWithDescription("testRequestResponse")
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testRequestResponseMixedPublishSubscribe() {
        responseCount = 2
        
        nutella?.net.handleRequest("test/mixed")
        nutella?.net.asyncRequest("test/mixed", message: "message", requestName: "test_request_mixed")
        
        nutella?.net.subscribe("test/mixed")
        nutella?.net.publish("test/mixed", message: ["ciao":"mondo"])
        
        expectation = expectationWithDescription("testRequestResponseMixexPublishSubscribe")
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testRequestResponseMixedPublishSubscribeWithUnsubscribe() {
        responseCount = 2
        
        nutella?.net.subscribe("test/mixed/unsubscribe")
        nutella?.net.publish("test/mixed/unsubscribe", message: ["ciao":"mondo"])
        
        nutella?.net.handleRequest("test/mixed/unsubscribe")
        nutella?.net.asyncRequest("test/mixed/unsubscribe", message: "message", requestName: "test_request_mixed")
        
        
        expectation = expectationWithDescription("testRequestResponseMixedPublishSubscribeWithUnsubscribe")
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testUnsubscribe() {
        responseCount = 1
        
        nutella?.net.subscribe("test/publish")
        nutella?.net.unsubscribe("test/publish")
        nutella?.net.subscribe("test/publish")
        nutella?.net.publish("test/publish", message: ["ciao":"mondo"])
        
        expectation = expectationWithDescription("testPublishSubscribe")
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    // MARK: NutellaNetDelegate
    var responseCount = 0;
    func responseReceived(channelName: String, requestName: String?, response: AnyObject) {
        if let status = response["status"] as? String {
            if requestName == "test_request1" && status == "ok" && channelName == "test/request1" {
                println(status)
                responseCount--
            }
        }
        
        if let status = response["status"] as? String {
            if requestName == "test_request2" && status == "ok" && channelName == "test/request2" {
                println(status)
                responseCount--
            }
        }
        
        if let status = response["status"] as? String {
            if requestName == "test_request_mixed" && status == "ok" && channelName == "test/mixed" {
                println(status)
                responseCount--
            }
        }
        
        if let status = response["status"] as? String {
            if requestName == "test_request_mixed" && status == "ok" && channelName == "test/mixed/unsubscribe" {
                println(status)
                responseCount--
            }
        }
        
        if(responseCount == 0) {
            expectation?.fulfill()
            expectation = nil
        }

    }
    
    func requestReceived(channelName: String, request: AnyObject, componentId: String?, resourceId: String?) -> AnyObject?{
        return ["status": "ok"]
    }
    
    func messageReceived(channel: String, message: AnyObject, componentId: String?, resourceId: String?) {
        var dictionary = message as Dictionary<String, String>
        if channel == "test/publish" && resourceId == "test_resource" && componentId == "test_component" && dictionary["ciao"] == "mondo" {
            responseCount--
            if(responseCount == 0) {
                expectation?.fulfill()
                expectation = nil
            }
        }
        
        if channel == "test/mixed" && resourceId == "test_resource" && componentId == "test_component" && dictionary["ciao"] == "mondo" {
            responseCount--
            if(responseCount == 0) {
                expectation?.fulfill()
                expectation = nil
            }
        }
        
        if channel == "test/mixed/unsubscribe" && resourceId == "test_resource" && componentId == "test_component" && dictionary["ciao"] == "mondo" {
            nutella?.net.unsubscribe("test/mixed/unsubscribe")
            responseCount--
            if(responseCount == 0) {
                expectation?.fulfill()
                expectation = nil
            }
        }
        
        if(responseCount == 0) {
            expectation?.fulfill()
            expectation = nil
        }
    }
    
    func testDoubleNutella() {
        responseCount = 2
        
        var nutella2 = Nutella(brokerHostname: "localhost", runId: "test_run", componentId: "test_component")
        nutella2.resourceId = "test_resource"
        nutella2.netDelegate = self
        
        nutella?.net.handleRequest("test/request1")
        nutella?.net.asyncRequest("test/request1", message: "message", requestName: "test_request1")
        
        nutella2.net.handleRequest("test/request1")
        nutella2.net.asyncRequest("test/request1", message: "message", requestName: "test_request1")
        
        expectation = expectationWithDescription("testPublishSubscribe")
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    
}