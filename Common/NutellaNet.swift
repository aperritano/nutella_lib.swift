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
    
    /**
        Initialize the module connecting it to the Nutella server.
    
        :param: host Hostname of the Nutella server.
        :param: clientId The client id. Leave it nil.
    */
    public init(host: String, clientId optionalClientId: String?) {
        self.mqtt = SimpleMQTTClient(host: host, synchronous: true, clientId: optionalClientId)
        self.mqtt.connect(host)
        self.host = host
        self.mqtt.delegate = self
    }
    
    /**
        Subscribe to a Nutella channel. Every time it will receive a message the delegate function messageReceived will be called.
        
        :param: channel The Nutella channel that you want to subscribe.
    */
    public func subscribe(channel: String) {
        mqtt.subscribe(urlInit+channel)
    }
    
    /**
        Unsubscribe from a Nutella channel.
    
        :param: channel The Nutella channel that you want to unsubscribe.
    */
    public func unsubscribe(channel: String) {
        mqtt.unsubscribe(urlInit+channel)
    }
    
    /**
        Publish a message on a Nutella channel.
    
        :param: channel The Nutella channel where you want to publish.
    */
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
    
    /**
        Execute a sychronous request of information on the specified Nutella channel.
    
        :param: channel The name of the channel on which executing the request.
        :param: message A dictionary that represent the message.
        :param: requestName An optional name assigned to the request in order to recognize it later.
    */
    public func syncRequest(channel: String, message: [String:AnyObject], requestName: String?) {
        var id = Int(arc4random_uniform(1000000000))
        // FIX: there's the possibility (1/1000000000 of times) that two requests have the same id. You're more likely to win the lottery.
        
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
    
    /**
        Not yet implemented, sorry, use syncRequest that is almost the same
    */
    public func asyncRequest(channel: String, message: String, requestName: String?) {
        
    }
    
    /**
        Handle a request coming from a client. The delegate function requestReceived will be invoked every time a new request is received.
    
        :param: channel The name of the Nutella channel on which listening.
    */
    public func handleRequest(channel: String) {
        handlingChannels.append(urlInit+channel)
        mqtt.subscribe(urlInit+channel)
    }
    
    /**
        Stop handing requests on the specified channel.
    
        :param: channel The Nutella channel on wich stopping to receiving requests.
    */
    public func unhandleRequest(channel: String) {
        let realChannel = urlInit + channel
        handlingChannels = handlingChannels.filter() { $0 != realChannel }  // Remove channel
        mqtt.unsubscribe(urlInit+channel)
    }
    
    // MARK: SimpleMQTTClientDelegate
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
