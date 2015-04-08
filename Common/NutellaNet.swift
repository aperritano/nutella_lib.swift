//
//  NutellaNet.swift
//  NutellaLib
//
//  Created by Gianluca Venturini on 12/01/15.
//  Copyright (c) 2015 Gianluca Venturini. All rights reserved.
//

import Foundation
import SimpleMQTTClient

/**
    This class is the Nutella module that takes care of the network connections and message delivery.
*/
public class NutellaNet: SimpleMQTTClientDelegate {
    class Subscription {
        var subscribe: Bool
        var request: Bool
        var response: Bool
        
        init(subscribe: Bool, request: Bool, response: Bool) {
            self.subscribe = subscribe
            self.request = request
            self.response = response
        }
        
        var subscribed: Bool {
            return subscribe || request || response
        }
    }
    
    
    weak var delegate: NutellaNetDelegate?
    weak var configDelegate: NutellaConfigDelegate?
    
    var mqtt: SimpleMQTTClient
    var host: String
    
    // Requests informations
    var requests = [Int:NutellaNetRequest]()
    
    // Subscribed channels
    var subscribed = [String: Subscription]()
    
    // Application run ID
    var urlInit: String {
        get {
            if let runId = self.configDelegate?.runId {
                if let appId = self.configDelegate?.appId {
                    return "/nutella/apps/" + appId + "/runs/" + runId + "/"
                }
                else {
                    return "/"
                }
            }
            else {
                return "/"
            }
        }
    }
    
    /**
        Initialize the module connecting it to the Nutella server.
    
        :param: host Hostname of the Nutella server.
        :param: clientId The client id. Leave it nil.
    */
    public init(host: String, clientId optionalClientId: String?) {
        self.mqtt = SimpleMQTTClient(host: host, synchronous: true, clientId: optionalClientId)
        self.host = host
        self.mqtt.delegate = self
        
        if(DEBUG) {
            println("[\(self)] init host: \(host) optionalClientId: \(optionalClientId)")
        }
    }
    
    /**
        Subscribe to a Nutella channel. Every time it will receive a message the delegate function messageReceived will be called.
        
        :param: channel The Nutella channel that you want to subscribe.
    */
    public func subscribe(channel: String) {
        if var subscription = self.subscribed[channel] {
            if subscription.subscribe != true {
                mqtt.subscribe(urlInit+channel)
                subscription.subscribe = true
            }
            else {
                println("WARNING: you're already subscribed to the channel " + channel)
            }
        }
        else {
            mqtt.subscribe(urlInit+channel)
            self.subscribed[channel] = Subscription(subscribe: true, request: false, response: false)
        }
    }
    
    /**
        Unsubscribe from a Nutella channel.
    
        :param: channel The Nutella channel that you want to unsubscribe.
    */
    public func unsubscribe(channel: String) {
        if(DEBUG) {
            println("[\(self)] unsubscribe channel: \(channel)")
        }
        
        if var subscription = self.subscribed[channel] {
            if subscription.subscribe == true {
                subscription.subscribe = false
                if subscription.subscribed == false {
                    mqtt.unsubscribe(urlInit+channel)
                }
            }
        }
        else {
            println("WARNING: you're not subscribed to the channel "+channel)
        }
    }
    
    /**
        Publish a message on a Nutella channel.
    
        :param: channel The Nutella channel where you want to publish.
    */
    public func publish(channel: String, message: AnyObject) {
        if(DEBUG) {
            println("[\(self)] publish channel: \(channel) message: \(message)")
        }
        
        var componentId: String = self.configDelegate!.componentId;
        var resourceId: String = "";
        var applicationId: String = self.configDelegate!.appId;
        var runId: String = self.configDelegate!.runId;
        
        if let rid = self.configDelegate?.resourceId {
            resourceId = rid
        }
        
        var from: [String:AnyObject] = ["type":"run",
            "run_id": runId,
            "app_id": applicationId,
            "resource_id": resourceId,
            "component_id": componentId
        ];
        
        var finalMessage: [String:AnyObject] = [String:AnyObject]()
        
        finalMessage = [
            "from": from,
            "type": "publish",
            "payload": message
        ]

        var json = JSON(finalMessage)
        
        mqtt.publish(urlInit+channel, message: json.rawString(options: nil)!)
    }
    
    /**
        Execute an asychronous request of information on the specified Nutella channel.
    
        :param: channel The name of the channel on which executing the request.
        :param: message A message that can be bot Dictionary or a String
        :param: requestName An optional name assigned to the request in order to recognize it later.
    */
    public func asyncRequest(channel: String, message: AnyObject, requestName: String?) {
        if(DEBUG) {
            println("[\(self)] asyncRequest channel: \(channel) message: \(message)")
        }
        
        var componentId: String = self.configDelegate!.componentId;
        var resourceId: String = "";
        var applicationId: String = self.configDelegate!.appId;
        var runId: String = self.configDelegate!.runId;
        
        if let rid = self.configDelegate?.resourceId {
            resourceId = rid
        }
        
        var id = Int(arc4random_uniform(1000000000))
        
        var from: [String:AnyObject] = ["type":"run",
            "run_id": runId,
            "app_id": applicationId,
            "resource_id": resourceId,
            "component_id": componentId
        ];
        
        requests[id] = NutellaNetRequest(channel: channel,
            id: id,
            name: requestName,
            message: message)
        
        if var subscription = self.subscribed[channel] {
            if subscription.subscribed == false {
                mqtt.subscribe(urlInit+channel)
            }
            
            if subscription.response == false {
                subscription.response = true
            }
            else {
                println("WARNING: you're already requesting on the channel "+channel)
            }
        }
        else {
            self.subscribed[channel] = Subscription(subscribe: false, request: false, response: true)
            mqtt.subscribe(urlInit+channel)
        }
        
        var finalMessage: [String:AnyObject] = [
            "id": id,
            "from": from,
            "type": "request",
            "payload": message
        ]
        
        var json = JSON(finalMessage)
        mqtt.publish(urlInit+channel, message: json.rawString(options: nil)!)
    }
    
    /**
        Not yet implemented, sorry, use asyncRequest that is almost the same
    */
    public func syncRequest(channel: String, message: String, requestName: String?) {
        println("WARNING: syncRequest method is not yet implemented, use asyncRequest")
    }
    
    /**
        Handle a request coming from a client. The delegate function requestReceived will be invoked every time a new request is received.
    
        :param: channel The name of the Nutella channel on which listening.
    */
    public func handleRequest(channel: String) {
        
        if(DEBUG) {
            println("[\(self)] handleRequest channel: \(channel)")
        }
        
        if var subscription = self.subscribed[channel] {
            if subscription.subscribed == false {
                mqtt.subscribe(urlInit+channel)
            }
            
            if subscription.request == false {
                subscription.request = true
            }
            else {
                println("WARNING: you're already handling requests on the channel "+channel)
            }
        }
        else {
            self.subscribed[channel] = Subscription(subscribe: false, request: true, response: false)
            mqtt.subscribe(urlInit+channel)
        }
    }
    
    /**
        Stop handing requests on the specified channel.
    
        :param: channel The Nutella channel on wich stopping to receiving requests.
    */
    public func unhandleRequest(channel: String) {
        
        if(DEBUG) {
            println("[\(self)] unhandleRequest channel: \(channel)")
        }
        
        let realChannel = urlInit + channel
        
        if var subscription = self.subscribed[channel] {
            if subscription.request == true {
                subscription.request = false
            }
            else {
                println("WARNING: You're not handling the requests on channel "+channel)
            }
            
            if subscription.subscribed == false {
                mqtt.unsubscribe(urlInit+channel)
            }
        }
        else {
            println("WARNING: You're not handling the requests on channel "+channel)
        }
        
    }
    
    // MARK: SimpleMQTTClientDelegate
    public func messageReceived(channel: String, message: String) {
        
        if(DEBUG) {
            println("[\(self)] messageReceived channel: \(channel) message: message")
        }
        
        if(channel == "") {
            return  // Discard messages arriving from nowhere
        }
        
        // Extract the eventual wildcard
        let wildcard = mqtt.wildcardSubscribed(channel)
        
        // Remove the runId from the channel
        var path:[String] = channel.componentsSeparatedByString("/")
        
        if path.count < 6 {
            return
        }
        
        path.removeAtIndex(0)
        path.removeAtIndex(0)
        path.removeAtIndex(0)
        path.removeAtIndex(0)
        path.removeAtIndex(0)
        path.removeAtIndex(0)
        let newChannel = "/".join(path)
        
        var subscriptionKey = newChannel
        
        if var w = wildcard {
            // Remove the runId from the wildcard
            path = w.componentsSeparatedByString("/")
            path.removeAtIndex(0)
            path.removeAtIndex(0)
            path.removeAtIndex(0)
            path.removeAtIndex(0)
            path.removeAtIndex(0)
            path.removeAtIndex(0)
            w = "/".join(path)
            
            subscriptionKey = w
        }
                
        var error: NSError?
        var data:NSData! = message.dataUsingEncoding(NSUTF8StringEncoding,
            allowLossyConversion: true)
        let jsonObject : AnyObject! = NSJSONSerialization.JSONObjectWithData(data,
            options: NSJSONReadingOptions.MutableContainers,
            error: nil)

        if let err = error {
            println("error parsing json")
        }
        else if let jsonDic = jsonObject as? NSDictionary {
            
            // States that the channel is in mode request/response
            var requestResponse = false
                        
            // Check if is a valid request
            if let id = jsonDic["id"] as? Int {
                if let type = jsonDic["type"] as? String {
                    if let from = jsonDic["from"] as? [String:AnyObject] {
                        
                        //var fromComponents:[String] = from.componentsSeparatedByString("/")
                        var componentId = ""
                        var resourceId = ""
                        
                        /*
                        if(fromComponents.count > 0) {
                            componentId = fromComponents[0];
                        }
                        if(fromComponents.count > 1) {
                            resourceId = fromComponents[1];
                        }
                        */
                        
                        if type == "request" {
                            if self.subscribed[subscriptionKey]?.request == true {
                                var payload: AnyObject? = nil
                                if let p: AnyObject = jsonDic["payload"] {
                                    payload = p
                                }
                                
                                // Reply if the delegate implements the requestReceived function
                                if let reply: AnyObject = self.delegate?.requestReceived?(newChannel, request: payload, componentId: componentId, resourceId: resourceId) {
                                    
                                    var componentId: String = self.configDelegate!.componentId;
                                    var resourceId: String = "";
                                    var applicationId: String = self.configDelegate!.appId;
                                    var runId: String = self.configDelegate!.runId;
                                    
                                    if let rid = self.configDelegate?.resourceId {
                                        resourceId = rid
                                    }
                                    
                                    //Publish the response
                                    
                                    var from: [String:AnyObject] = ["type":"run",
                                        "run_id": runId,
                                        "app_id": applicationId,
                                        "resource_id": resourceId,
                                        "component_id": componentId
                                    ];
                                    
                                    var finalMessage: [String:AnyObject] = [
                                        "id": id,
                                        "from": from,
                                        "type": "response"]
                                    
                                    finalMessage["payload"] = reply
                                        
                                    var json = JSON(finalMessage)
                                    
                                    mqtt.publish(channel, message: json.rawString(options: nil)!)
                                    
                                    requestResponse = true
                                }
                            }
                        }
                    }
                }
            }
            
            // Check if is a valid publish message
            if let type = jsonDic["type"] as? String {
                if let from = jsonDic["from"] as? [String:AnyObject] {
                    
                    //var fromComponents:[String] = from.componentsSeparatedByString("/")
                    var componentId = ""
                    var resourceId = ""
                    
                    /*
                    if(fromComponents.count > 0) {
                        componentId = fromComponents[0];
                    }
                    if(fromComponents.count > 1) {
                        resourceId = fromComponents[1];
                    }
                    */
                    
                    if type == "publish" {
                        if let payload: AnyObject = jsonDic["payload"] {
                            if self.subscribed[subscriptionKey]?.subscribe == true {
                                self.delegate?.messageReceived?(newChannel, message: payload, componentId: componentId, resourceId: resourceId)
                            }
                        }
                    }
                }
            }
            
            // Check if is a valid response
            if let id = jsonDic["id"] as? Int {
                if let type = jsonDic["type"] as? String {
                    if let payload: AnyObject = jsonDic["payload"] {
                        if let from = jsonDic["from"] as? [String:AnyObject] {
                            
                            //var fromComponents:[String] = from.componentsSeparatedByString("/")
                            var componentId = ""
                            var resourceId = ""
                            
                            /*
                            if(fromComponents.count > 0) {
                                componentId = fromComponents[0];
                            }
                            if(fromComponents.count > 1) {
                                resourceId = fromComponents[1];
                            }
                            */
                            
                            if type == "response" {
                                if let request = requests[id] {
                                    if self.subscribed[subscriptionKey]?.response == true {
                                        self.delegate?.responseReceived?(newChannel, requestName: request.name, response: payload)
                                        self.subscribed[subscriptionKey]!.response = false
                                        
                                        if self.subscribed[subscriptionKey]!.subscribed == false {
                                            mqtt.unsubscribe(channel)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
            
            /*
            
            // Check if is a valid response
            if let id = jsonDic["id"] as? Int {
                if let messageType = jsonDic["messageType"] as? String {
                    if messageType == "response" {
                        if let request = requests[id] {
                            //println("Valid response")
                            self.delegate?.responseReceived?(newChannel,
                                requestName: request.name,
                                response: jsonDic)
                            
                            requestResponse = true
                        }
                    }
                }
            }
            
            if requestResponse == false {
                if let from = jsonDic["from"] as? String {
                    self.delegate?.messageReceived?(newChannel, message: jsonDic, from: from)
                }
            }
        }

        */
    
    public func disconnected() {
        // Do nothing and wait for the reconnection
    }
    
    public func connected() {
    }
}
