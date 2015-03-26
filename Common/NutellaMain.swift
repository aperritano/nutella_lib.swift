//
//  NutellaLib.swift
//  
//
//  Created by Gianluca Venturini on 12/01/15.
//  For generating documentation:
//  jazzy -o doc -a "Gianluca Venturini" -g "https://github.com/nutella-framework/nutella_lib.swift.git" --skip-undocumented
//

#if DEBUG
    let DEBUG = true
#else
    let DEBUG = false
#endif

import Foundation

/**
    This is the main class that contains all the modules. It acts as a interface with the external world.
*/
public class Nutella: NutellaConfigDelegate {
    var componentId: String
    var runId: String
    
    public var resourceId: String? {
        get {
            return self.location.resourceId
        }
        set(resourceId) {
            self.location.resourceId = resourceId
        }
    }
    
    
    /**
        Nutella network module, it enable the explicit interaction using MQTT protocol.
    */
    public var net: NutellaNet
    
    /**
        Nutella location module, it enable the detection of near beacon
    */
    public var location: NutellaLocation
    
    /**
        The NutellaDelegateused in order to manage the notification about the status of Nutella.
    */
    public weak var delegate: NutellaDelegate?
    
    /**
        Designated initializer.
    
        :param: host The hostname on which it runs the Nutella server.
        :param: actorName The name of the actor client.
        :param: runId The run id of the instance of the application.
        :param: clientId The client id used for techinical reason. Do not use it unless you have a valid motivation, the system will take care of generating it if left null
    */
    public init(brokerHostname: String, runId: String, componentId: String) {
        
        self.componentId = componentId
        self.runId = runId
        self.net = NutellaNet(host: brokerHostname, clientId: nil)
        self.location = NutellaLocation(locationServer: brokerHostname)
        
        if(DEBUG) {
            println("[\(self)] init brokerHostname: \(brokerHostname) runId: \(runId) componentId: \(componentId)")
        }
        
        self.net.configDelegate = self
        self.location.configDelegate = self
        
        self.location.downloadBeaconList()
        self.location.downloadResourceList()
        
        self.location.startMonitorning()
        self.location.subscribeResourceUpdate()
    }
    
    /**
        Nutella newtork module delegate.
    */
    
    public var netDelegate: NutellaNetDelegate? {
        get {
            return self.net.delegate
        }
        set(delegate) {
            self.net.delegate = delegate
        }
    }
    
    /**
        Nutella location module delegate
    */
    public var locationDelegate: NutellaLocationDelegate? {
        get {
            return self.location.delegate
        }
        set(delegate) {
            self.location.delegate = delegate
        }
    }
    
    
    
}
