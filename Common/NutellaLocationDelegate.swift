//
//  NutellaLocationDelegate.swift
//  
//
//  Created by Gianluca Venturini on 25/03/15.
//
//

import Foundation

/**
    This protocol enable the monitoring of the Room Places resources
*/
public protocol NutellaLocationDelegate {
    
    func managedResourceUpdated(resource: NLManagedResource)
}