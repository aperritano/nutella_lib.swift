//
//  NutellaLocationDelegate.swift
//  


import Foundation

/**
    This protocol enable the monitoring of the Room Places resources
*/
public protocol NutellaLocationDelegate {
    
    func resourceUpdated(resource: NLManagedResource)
    func resourceEntered(dynamicResource: NLManagedResource, staticResource: NLManagedResource)
    func resourceExited(dynamicResource: NLManagedResource, staticResource: NLManagedResource)
    func ready()
}