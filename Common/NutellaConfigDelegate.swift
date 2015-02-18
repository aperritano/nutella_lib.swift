//
//  NutellaConfigDelegate.swift
//  
//
//  Created by Gianluca Venturini on 24/01/15.
//
//

import Foundation

@objc protocol NutellaConfigDelegate {
    var runId: String { get }
    var componentId: String { get }
    var resourceId: String? { get }
}


