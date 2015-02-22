//
//  NutellaNetDelegate.swift
//  NutellaLib
//
//  Created by Gianluca Venturini on 12/01/15.
//  Copyright (c) 2015 Gianluca Venturini. All rights reserved.
//

import Foundation

/**
    This protocol allows client to control the asynchronous requests, response and message received
*/
@objc public protocol NutellaNetDelegate {
    /**
        Called when a message is received from a publish.
        
        :param: channel The name of the Nutella chennal on which the message is received.
        :param: message The message.
        :param: from The actor name of the client that sent the message.
    */
    optional func messageReceived(channel: String, message: AnyObject, componentId: String?, resourceId: String?)
    
    /**
        A response to a previos request is received.
        
        :param: channelName The Nutella channel on which the message is received.
        :param: requestName The optional name of request.
        :param: response The dictionary/array/string containing the JSON representation.
    */
    optional func responseReceived(channelName: String, requestName: String?, response: AnyObject)
    
    /**
        A request is received on a Nutella channel that was previously handled (with the handleRequest).
        
        :param: channelName The name of the Nutella chennal on which the request is received.
        :param: request The dictionary/array/string containing the JSON representation of the request.
    */
    optional func requestReceived(channelName: String, request: AnyObject?, componentId: String?, resourceId: String?) -> AnyObject?
}
