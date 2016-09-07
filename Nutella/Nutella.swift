//
//  NutellaLib.swift
//  
//
//  Created by Gianluca Venturini on 12/01/15.
//  For generating documentation:
//  jazzy -o doc -a "Gianluca Venturini" -g "https://github.com/nutella-framework/nutella_lib.swift.git" --skip-undocumented
//


import Foundation

let DEBUG = false

/**
    This is the main class that contains all the modules. It acts as a interface with the external world.
*/
open class Nutella: NutellaConfigDelegate {
    var componentId: String
    var runId: String
    var appId: String
    
    /**
        Nutella network module, it enable the explicit interaction using MQTT protocol.
    */
    open var net: NutellaNet
    
    /**
        The NutellaDelegateused in order to manage the notification about the status of Nutella.
    */
    open weak var delegate: NutellaDelegate?
    
    /**
        Designated initializer.
    
        - parameter host: The hostname on which it runs the Nutella server.
        - parameter actorName: The name of the actor client.
        - parameter runId: The run id of the instance of the application.
        - parameter clientId: The client id used for techinical reason. Do not use it unless you have a valid motivation, the system will take care of generating it if left null
    */
    public init(brokerHostname: String, appId: String, runId: String, componentId: String, netDelegate: NutellaNetDelegate? = nil) {
        
        self.componentId = componentId
        self.runId = runId
        self.appId = appId
        self.net = NutellaNet(host: brokerHostname, clientId: nil)
        self.netDelegate = netDelegate
        
        
        if(DEBUG) {
            print("[\(self)] init brokerHostname: \(brokerHostname) appId: \(appId) runId: \(runId) componentId: \(componentId)")
        }
        
        self.net.configDelegate = self
    }
    
    /**
        Nutella newtork module delegate.
    */
    
    open var netDelegate: NutellaNetDelegate? {
        get {
            return self.net.delegate
        }
        set(delegate) {
            self.net.delegate = delegate
        }
    }

}
