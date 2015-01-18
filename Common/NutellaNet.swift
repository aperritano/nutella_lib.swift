//
//  NutellaNet.swift
//  NutellaLib
//
//  Created by Gianluca Venturini on 12/01/15.
//  Copyright (c) 2015 Gianluca Venturini. All rights reserved.
//

import Foundation
import SimpleMQTTClient

public class NutellaNet: SimpleMQTTClientDelegate {
    weak var delegate: NutellaNetDelegate?
    
    var mqtt: SimpleMQTTClient
    var host: String
    
    // Requests informations
    var requests = [Int:NutellaNetRequest]()
    
    // Handling channel informations
    var handlingChannels = [String]()
    
    // Application run ID
    var urlInit: String {
        get {
            if let runId = self.delegate?.runId {
                return runId + "/"
            }
            else {
                return "/"
            }
        }
    }
    
    public init(host: String, clientId optionalClientId: String?) {
        self.mqtt = SimpleMQTTClient(host: host, synchronous: true, clientId: optionalClientId)
        self.mqtt.connect(host)
        self.host = host
        self.mqtt.delegate = self
    }
    
    public func subscribe(channel: String) {
        mqtt.subscribe(urlInit+channel)
    }
    
    public func unsubscribe(channel: String) {
        mqtt.unsubscribe(urlInit+channel)
    }
    
    public func publish(channel: String, message: AnyObject) {
        var actorName = ""
        if let an = delegate?.actorName {
            actorName = an
        }
        var finalMessage: [String:AnyObject] = ["payload": message,
                                                "from": actorName]
        var json = JSON(finalMessage)
        
        mqtt.publish(urlInit+channel, message: json.rawString(options: nil)!)
    }
    
    public func syncRequest(channel: String, message: [String:AnyObject], requestName: String?) {
        var id = Int(arc4random_uniform(1000000000))
        
        requests[id] = NutellaNetRequest(channel: channel,
            id: id,
            name: requestName,
            message: message)
        
        mqtt.subscribe(urlInit+channel)
        
        var finalMessage: [String:AnyObject] = ["payload": message,
                                                "id": id,
                                                "messageType": "request"]
        
        var json = JSON(finalMessage)
        mqtt.publish(urlInit+channel, message: json.rawString(options: nil)!)
    }
    
    public func asyncRequest(channel: String, message: String, requestName: String?) {
        
    }
    
    public func handleRequest(channel: String) {
        handlingChannels.append(urlInit+channel)
        mqtt.subscribe(urlInit+channel)
    }
    
    public func unhandleRequest(channel: String) {
        let realChannel = urlInit + channel
        handlingChannels = handlingChannels.filter() { $0 != realChannel }  // Remove channel
        mqtt.unsubscribe(urlInit+channel)
    }
    
    // SimpleMQTTClientDelegate
    public func messageReceived(channel: String, message: String) {
        
        // Remove the runId
        var path:[String] = channel.componentsSeparatedByString("/")
        path.removeAtIndex(0)
        let newChannel = "/".join(path)
        
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
                if let messageType = jsonDic["messageType"] as? String {
                    if messageType == "request" {
                        if let payload: AnyObject = jsonDic["payload"] {
                            if contains(self.handlingChannels, channel) {
                                //println("Valid request")
                                // Reply if the delegate implements the requestReceived function
                                if let reply: AnyObject = self.delegate?.requestReceived(newChannel, request: payload) {
                                    
                                    //Publish the message
                                    var finalMessage: [String:AnyObject] = ["id": id,
                                        "messageType": "response",
                                        "payload": reply]
                                    var json = JSON(finalMessage)
                                    
                                    mqtt.publish(channel, message: json.rawString(options: nil)!)
                                    
                                    requestResponse = true
                                }
                            }
                        }
                    }
                }
            }
            
            // Check if is a valid response
            if let id = jsonDic["id"] as? Int {
                if let messageType = jsonDic["messageType"] as? String {
                    if messageType == "response" {
                        if let payload: AnyObject = jsonDic["payload"] {
                            if let request = requests[id] {
                                //println("Valid response")
                                self.delegate?.responseReceived(newChannel,
                                    requestName: request.name,
                                    response: payload)
                                
                                requestResponse = true
                            }
                        }
                    }
                }
            }
            
            if requestResponse == false {
                if let from = jsonDic["from"] as? String {
                    if let payload: AnyObject = jsonDic["payload"] {
                        self.delegate?.messageReceived(newChannel, message: payload, from: from)
                    }
                }
            }
        }
        
        
    }
    
    public func disconnected() {
        mqtt.connect(self.host)
    }
    
    public func connected() {
    }
}
