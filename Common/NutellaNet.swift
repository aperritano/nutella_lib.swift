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
    
    
    public init(host: String, clientId optionalClientId: String?) {
        self.mqtt = SimpleMQTTClient(host: host, synchronous: true, clientId: optionalClientId)
        self.mqtt.connect(host)
        self.host = host
        self.mqtt.delegate = self
    }
    
    public func subscribe(channel: String) {
        mqtt.subscribe(channel)
    }
    
    public func unsubscribe(channel: String) {
        mqtt.unsubscribe(channel)
    }
    
    public func publish(channel: String, message: [String:AnyObject]) {
        var actorName = ""
        if let an = delegate?.actorName {
            actorName = an
        }
        var finalMessage: [String:AnyObject] = ["payload": message,
                                                "from": actorName]
        var json = JSON(finalMessage)
        
        mqtt.publish(channel, message: json.description)
    }
    
    public func syncRequest(channel: String, message: [String:AnyObject], requestName: String?) {
        var id = Int(arc4random_uniform(1000000000))
        
        requests[id] = NutellaNetRequest(channel: channel,
            id: id,
            name: requestName,
            message: message)
        
        mqtt.subscribe(channel)
        
        var finalMessage: [String:AnyObject] = ["payload": message,
                                                "id": id,
                                                "messageType": "request"]
        
        var json = JSON(finalMessage)
        mqtt.publish(channel, message: json.rawString(options: nil)!)
    }
    
    public func asyncRequest(channel: String, message: String, requestName: String?) {
        
    }
    
    public func handleRequest(channel: String) {
        handlingChannels.append(channel)
        mqtt.subscribe(channel)
    }
    
    // SimpleMQTTClientDelegate
    public func messageReceived(channel: String, message: String) {
        
        var error: NSError?
        var data:NSData! = message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        let jsonDict : NSDictionary? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &error) as? NSDictionary
        if let err = error {
            println("error parsing json")
        }
        else if let jd = jsonDict {
            var json = JSON(jd)
            
            println(json)
            
            // Check if is a valid request
            if json["id"].int != nil &&
               json["messageType"].string == "request"{
                println("Valid request")
                
                // Check if it is an handled channel
                if contains(handlingChannels, channel) {
                    if let response = self.delegate?.requestReceived?(channel, request: json["payload"].rawString(options: nil)!) {
                        // Send the reply on the same channel
                        publish(channel, message: response)
                    }
                }
            }
            
            // Check if is a valid response
            if json["id"].int != nil &&
                json["messageType"].string == "response" {
                if let request = requests[json["id"].int!] {
                    println("Valid response")
                    if json["payload"] != nil {
                        self.delegate?.responseReceived?(channel,
                                                         requestName: request.name,
                                                         response: json["payload"].rawString(options: nil)!)
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
