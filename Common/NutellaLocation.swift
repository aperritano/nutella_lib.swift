//
//  NutellaLocation.swift
//  
//
//  Created by Gianluca Venturini on 24/01/15.
//
//

import Foundation
import CoreLocation

public class NutellaLocation: NSObject, NutellaNetDelegate, CLLocationManagerDelegate {
    
    var _configDelegate: NutellaConfigDelegate?
    var configDelegate: NutellaConfigDelegate? {
        get {
            return _configDelegate
        }
        
        set(delegate) {
            _configDelegate = delegate
            self.net.configDelegate = delegate
        }
    }
    
    var regions = [CLBeaconRegion]()
    
    let locationManager = CLLocationManager()
    
    let net: NutellaNet
    
    init(locationServer: String) {
        
        // Initialize nutella net instance
        net = NutellaNet(host: locationServer, clientId: nil)
        
        super.init()
        
        println("Location initialization")
        
        net.delegate = self
        
        // Request the authorization to access the user location in every moment
        locationManager.requestAlwaysAuthorization()
        
        locationManager.delegate = self
    }
    
    public func startMonitoringRegions(uuids: [String]) {
        for uuid in uuids {
            var region: CLBeaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: uuid), identifier: uuid)
            self.locationManager.startRangingBeaconsInRegion(region)
            self.regions.append(region)
        }
    }
    
    public func startMonitorning() {
        // Request the beacon cloud service for the uuids list
        
        self.net.asyncRequest("beacon/beacons/uuids", message: [], requestName: "uuids")
    }
    
    public func stopMonitoring() {
        for region in self.regions {
            self.locationManager.stopMonitoringForRegion(region)
        }
    }
    
    public func locationManager(manager: CLLocationManager, didRangeBeacons: [AnyObject], inRegion: CLBeaconRegion) {
        println("Monitor region")
        for beacon in didRangeBeacons {
            println(beacon.proximityUUID);
            println(beacon.major);
            println(beacon.minor);
            println(beacon.proximity);
        }
    }
    
    
    
    // MARK: NutellaNetDelegate
    
    /*
    public func messageReceived(channel: String, message: AnyObject, from: String) {
        
    }
    */
    
    public func responseReceived(channelName: String, requestName: String?, response: AnyObject) {
        if requestName == "uuids" {
            if let r = response as? Dictionary<String, [String]> {
                if let uuids = response["uuids"] as? [String] {
                    self.startMonitoringRegions(uuids)
                }
            }
        }
    }
    
    /*
    public func requestReceived(channelName: String, request: AnyObject) -> AnyObject? {
        
    }
    */
    
    /*
    
    // MARK: ESTBeaconManagerDelegate
    func beaconManager(manager: ESTBeaconManager, didRangeBeacons: [ESTBeacon], inRegion: ESTBeaconRegion) {
        println("I've found \(didRangeBeacons.count) in range")
        
        for beacon in didRangeBeacons {
            //println("----")
            //println("Majour: \(beacon.major)")
            //println("Minor: \(beacon.minor)")
            //println("RSSI: \(beacon.rssi)")
            //println("Distance: \(beacon.distance)")
            //sprintln("Name: \(beacon.name)")
            
            if let name: String = beacon.name {
                if beacon.distance.doubleValue > 0 {
                    println("Name: \(beacon.name)")
                    
                    if let actorName = configDelegate?.actorName {
                        var location: [String: AnyObject] = ["rid": actorName,
                            "proximity": ["rid": name,
                                "distance": beacon.distance.stringValue,
                                "rssi": String(beacon.rssi)]]
                        
                        net.publish("location/update", message: location)
                        println("Message published")
                    }
                }
                
            }
        }
    }

    */
}