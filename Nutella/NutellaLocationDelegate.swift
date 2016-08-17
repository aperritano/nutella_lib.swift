//
//  NutellaLocationDelegate.swift
//  


import Foundation

/**
    This protocol enable the monitoring of the Room Places resources
*/
public protocol NutellaLocationDelegate {
    
    func resourceUpdated(_ resource: NLManagedResource)
    func resourceEntered(_ dynamicResource: NLManagedResource, staticResource: NLManagedResource)
    func resourceExited(_ dynamicResource: NLManagedResource, staticResource: NLManagedResource)
    func ready()
}
