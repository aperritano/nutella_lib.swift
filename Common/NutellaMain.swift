//
//  NutellaLib.swift
//  
//
//  Created by Gianluca Venturini on 12/01/15.
//
//

import Foundation

public class Nutella: NutellaNetDelegate {
    var actorName: String
    var runId: String
    
    public var net: NutellaNet
    
    public weak var delegate: NutellaDelegate?
    
    public init(host: String, actorName: String, runId: String, clientId: String? = nil) {
        self.actorName = actorName
        self.runId = runId
        self.net = NutellaNet(host: host, clientId: clientId)
        
        self.net.delegate = self
    }
    
    // NutellaNetDelegate
    
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
