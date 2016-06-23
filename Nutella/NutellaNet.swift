//
//  NutellaNet.swift
//  NutellaLib

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
    var subscribed : [String: Subscription] = [String: Subscription]()
    
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
    
        - parameter host: Hostname of the Nutella server.
        - parameter clientId: The client id. Leave it nil.
    */
    public init(host: String, clientId optionalClientId: String?) {
        self.mqtt = SimpleMQTTClient(host: host, synchronous: true, clientId: optionalClientId)
        self.host = host
        self.mqtt.delegate = self
        
        if(DEBUG) {
            print("[\(self)] init host: \(host) optionalClientId: \(optionalClientId)")
        }
    }
    
    /**
        Subscribe to a Nutella channel. Every time it will receive a message the delegate function messageReceived will be called.
        
        - parameter channel: The Nutella channel that you want to subscribe.
    */
    public func subscribe(channel: String) {
        if let subscription = self.subscribed[channel] {
            if subscription.subscribe != true {
                mqtt.subscribe(urlInit+channel)
                subscription.subscribe = true
            }
            else {
                print("WARNING: you're already subscribed to the channel " + channel)
            }
        }
        else {
            mqtt.subscribe(urlInit+channel)
            self.subscribed[channel] = Subscription(subscribe: true, request: false, response: false)
        }
    }
    
    /**
        Unsubscribe from a Nutella channel.
    
        - parameter channel: The Nutella channel that you want to unsubscribe.
    */
    public func unsubscribe(channel: String) {
        if(DEBUG) {
            print("[\(self)] unsubscribe channel: \(channel)")
        }
        
        if let subscription = self.subscribed[channel] {
            if subscription.subscribe == true {
                subscription.subscribe = false
                if subscription.subscribed == false {
                    mqtt.unsubscribe(urlInit+channel)
                }
            }
        }
        else {
            print("WARNING: you're not subscribed to the channel "+channel)
        }
    }
    
    /**
        Publish a message on a Nutella channel.
    
        - parameter channel: The Nutella channel where you want to publish.
    */
    public func publish(channel: String, message: AnyObject) {
        if(DEBUG) {
            print("[\(self)] publish channel: \(channel) message: \(message)")
        }
        
        let componentId: String = self.configDelegate!.componentId;
        var resourceId: String = "";
        let applicationId: String = self.configDelegate!.appId;
        let runId: String = self.configDelegate!.runId;
        
        if let rid = self.configDelegate?.resourceId {
            resourceId = rid
        }
        
        let from: [String:AnyObject] = ["type":"run",
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

        let json = JSON(finalMessage)
        
        mqtt.publish(urlInit+channel, message: json.toString())
    }
    
    /**
        Execute an asychronous request of information on the specified Nutella channel.
    
        - parameter channel: The name of the channel on which executing the request.
        - parameter message: A message that can be bot Dictionary or a String
        - parameter requestName: An optional name assigned to the request in order to recognize it later.
    */
    public func asyncRequest(channel: String, message: AnyObject, requestName: String?) {
        if(DEBUG) {
            print("[\(self)] asyncRequest channel: \(channel) message: \(message)")
        }
        
        let componentId: String = self.configDelegate!.componentId;
        var resourceId: String = "";
        let applicationId: String = self.configDelegate!.appId;
        let runId: String = self.configDelegate!.runId;
        
        if let rid = self.configDelegate?.resourceId {
            resourceId = rid
        }
        
        let id = Int(arc4random_uniform(1000000000))
        
        let from: [String:AnyObject] = ["type":"run",
            "run_id": runId,
            "app_id": applicationId,
            "resource_id": resourceId,
            "component_id": componentId
        ];
        
        requests[id] = NutellaNetRequest(channel: channel,
            id: id,
            name: requestName,
            message: message)
        
        if let subscription = self.subscribed[channel] {
            if subscription.subscribed == false {
                mqtt.subscribe(urlInit+channel)
            }
            
            if subscription.response == false {
                subscription.response = true
            }
            else {
                print("WARNING: you're already requesting on the channel "+channel)
            }
        }
        else {
            self.subscribed[channel] = Subscription(subscribe: false, request: false, response: true)
            mqtt.subscribe(urlInit+channel)
        }
        
        let finalMessage: [String:AnyObject] = [
            "id": id,
            "from": from,
            "type": "request",
            "payload": message
        ]
        
        let json = JSON(finalMessage)
        mqtt.publish(urlInit+channel, message: json.toString())
    }
    
    /**
        Not yet implemented, sorry, use asyncRequest that is almost the same
    */
    public func syncRequest(channel: String, message: String, requestName: String?) {
        print("WARNING: syncRequest method is not yet implemented, use asyncRequest")
    }
    
    /**
        Handle a request coming from a client. The delegate function requestReceived will be invoked every time a new request is received.
    
        - parameter channel: The name of the Nutella channel on which listening.
    */
    public func handleRequest(channel: String) {
        
        if(DEBUG) {
            print("[\(self)] handleRequest channel: \(channel)")
        }
        
        if let subscription = self.subscribed[channel] {
            if subscription.subscribed == false {
                mqtt.subscribe(urlInit+channel)
            }
            
            if subscription.request == false {
                subscription.request = true
            }
            else {
                print("WARNING: you're already handling requests on the channel "+channel)
            }
        }
        else {
            self.subscribed[channel] = Subscription(subscribe: false, request: true, response: false)
            mqtt.subscribe(urlInit+channel)
        }
    }
    
    /**
        Stop handing requests on the specified channel.
    
        - parameter channel: The Nutella channel on wich stopping to receiving requests.
    */
    public func unhandleRequest(channel: String) {
        
        if(DEBUG) {
            print("[\(self)] unhandleRequest channel: \(channel)")
        }
        
        _ = urlInit + channel
        
        if let subscription = self.subscribed[channel] {
            if subscription.request == true {
                subscription.request = false
            }
            else {
                print("WARNING: You're not handling the requests on channel "+channel)
            }
            
            if subscription.subscribed == false {
                mqtt.unsubscribe(urlInit+channel)
            }
        }
        else {
            print("WARNING: You're not handling the requests on channel "+channel)
        }
        
    }
    
    // MARK: SimpleMQTTClientDelegate
    @objc public func messageReceived(channel: String, message: String) {
        
        if(DEBUG) {
            print("[\(self)] messageReceived channel: \(channel) message: message")
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
        let newChannel = path.joinWithSeparator("/")
        
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
            w = path.joinWithSeparator("/")
            
            subscriptionKey = w
        }
                
        var error: NSError?
        let data:NSData! = message.dataUsingEncoding(NSUTF8StringEncoding,
            allowLossyConversion: true)
        let jsonObject : AnyObject! = try? NSJSONSerialization.JSONObjectWithData(data,
            options: NSJSONReadingOptions.MutableContainers)

        if error != nil {
            print("error parsing json")
        }
        else if let jsonDic = jsonObject as? NSDictionary {
            
            // States that the channel is in mode request/response
            var requestResponse = false
                        
            // Check if is a valid request
            if let id = jsonDic["id"] as? Int {
                if let type = jsonDic["type"] as? String {
                    if let from = jsonDic["from"] as? [String:AnyObject] {
                        
                        //var fromComponents:[String] = from.componentsSeparatedByString("/")
                        let componentId = ""
                        let resourceId = ""
                        
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
                                    
                                    let componentId: String = self.configDelegate!.componentId;
                                    var resourceId: String = "";
                                    let applicationId: String = self.configDelegate!.appId;
                                    let runId: String = self.configDelegate!.runId;
                                    
                                    if let rid = self.configDelegate?.resourceId {
                                        resourceId = rid
                                    }
                                    
                                    //Publish the response
                                    
                                    let from: [String:AnyObject] = ["type":"run",
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
                                        
                                    let json = JSON(finalMessage)
                                    
                                    mqtt.publish(channel, message: json.toString())
                                    
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
                    let componentId = ""
                    let resourceId = ""
                    
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
                            _ = ""
                            
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
    
    @objc public func disconnected() {
        // Do nothing and wait for the reconnection
    }
    
    @objc public func connected() {
    }
}
