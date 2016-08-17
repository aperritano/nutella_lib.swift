//
//  NutellaNetDelegate.swift
//

import Foundation

/**
    This protocol allows client to control the asynchronous requests, response and message received
*/
@objc public protocol NutellaNetDelegate {
    /**
        Called when a message is received from a publish.
        
        - parameter channel: The name of the Nutella chennal on which the message is received.
        - parameter message: The message.
        - parameter from: The actor name of the client that sent the message.
    */
    @objc optional func messageReceived(_ channel: String, message: AnyObject, componentId: String?, resourceId: String?)
    
    /**
        A response to a previos request is received.
        
        - parameter channelName: The Nutella channel on which the message is received.
        - parameter requestName: The optional name of request.
        - parameter response: The dictionary/array/string containing the JSON representation.
    */
    @objc optional func responseReceived(_ channelName: String, requestName: String?, response: AnyObject)
    
    /**
        A request is received on a Nutella channel that was previously handled (with the handleRequest).
        
        - parameter channelName: The name of the Nutella chennal on which the request is received.
        - parameter request: The dictionary/array/string containing the JSON representation of the request.
    */
    @objc optional func requestReceived(_ channelName: String, request: AnyObject?, componentId: String?, resourceId: String?) -> AnyObject?
}
