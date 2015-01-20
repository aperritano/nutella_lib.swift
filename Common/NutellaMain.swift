//
//  NutellaLib.swift
//  
//
//  Created by Gianluca Venturini on 12/01/15.
//  For generating documentation:
//  jazzy -o doc -a "Gianluca Venturini" -g "https://github.com/nutella-framework/nutella_lib.swift.git" --skip-undocumented
//

import Foundation

/**
    This is the main class that contains all the modules. It acts as a interface with the external world.
*/
public class Nutella: NutellaNetDelegate {
    var actorName: String
    var runId: String
    
    /**
        Nutella network module, it enable the explicit interaction using MQTT protocol.
    */
    public var net: NutellaNet
    
    /**
        The NutellaDelegateused in order to manage the notification about the status of Nutella.
    */
    public weak var delegate: NutellaDelegate?
    
    /**
        Designated initializer.
    
        :param: host The hostname on which it runs the Nutella server.
        :param: actorName The name of the actor client.
        :param: runId The run id of the instance of the application.
        :param: clientId The client id used for techinical reason. Do not use it unless you have a valid motivation, the system will take care of generating it if left null
    */
    public init(host: String, actorName: String, runId: String, clientId: String? = nil) {
        self.actorName = actorName
        self.runId = runId
        self.net = NutellaNet(host: host, clientId: clientId)
        
        self.net.delegate = self
    }
    
    // MARK: NutellaNetDelegate
    
    func messageReceived(channel: String, message: AnyObject, from: String) {
        self.delegate?.messageReceived?(channel, message: message, from: from)
    }
    
    func responseReceived(channelName: String, requestName: String?, response: AnyObject) {
        self.delegate?.responseReceived?(channelName, requestName: requestName, response: response)
    }
    
    func requestReceived(channelName: String, request: AnyObject) -> AnyObject? {
        return self.delegate?.requestReceived?(channelName, request: request)
    }
}
