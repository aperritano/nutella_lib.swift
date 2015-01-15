//
//  NutellaNetDelegate.swift
//  NutellaLib
//
//  Created by Gianluca Venturini on 12/01/15.
//  Copyright (c) 2015 Gianluca Venturini. All rights reserved.
//

import Foundation

@objc protocol NutellaNetDelegate {
    var actorName: String { get }
    var runId: String { get }
    
    optional func messageReceived(channel: String, message: String)
    
    optional func responseReceived(channelName: String, requestName: String?, response: String)
    optional func requestReceived(channelName: String, request: String) -> [String:AnyObject]?
}
