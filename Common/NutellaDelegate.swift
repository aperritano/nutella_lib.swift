//
//  NutellaDelegate.swift
//  NutellaLib
//
//  Created by Gianluca Venturini on 12/01/15.
//  Copyright (c) 2015 Gianluca Venturini. All rights reserved.
//

import Foundation

// This protocol allows client to control the asynchronous callback
@objc public protocol NutellaDelegate {
    optional func messageReceived(channel: String, message: AnyObject, from: String)
    
    optional func responseReceived(channelName: String, requestName: String?, response: AnyObject)
    optional func requestReceived(channelName: String, request: AnyObject) -> AnyObject?
}
