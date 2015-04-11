//
//  NutellaConfigDelegate.swift
//  
//
//  Created by Gianluca Venturini on 24/01/15.
//
//

import Foundation

protocol NutellaConfigDelegate: class {
    var runId: String { get }
    var appId: String { get }
    var componentId: String { get }
    var resourceId: String? { get }
}


