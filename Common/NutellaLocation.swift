//
//  NutellaLocation.swift
//  
//
//  Created by Gianluca Venturini on 24/01/15.
//
//

import Foundation
import CoreLocation

struct NLBeacon {
    var uuid: String
    var minor: Int
    var major: Int
    var rid: String
}

func == (left: NLBeacon, right: CLBeacon) -> Bool {
    return left.uuid.lowercaseString == right.proximityUUID.UUIDString.lowercaseString &&
        left.minor == right.minor &&
        left.major == right.major
}

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
    
    var beacons = [String:NLBeacon]()
    
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
    
    public func downloadBeaconList() {
        // Download the list of beacons from the cloud
        self.net.asyncRequest("beacon/beacons", message: [:], requestName: "beacons")
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
        
        self.net.asyncRequest("beacon/uuids", message: [:], requestName: "uuids")
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
            
            if let myRid = self.configDelegate?.resourceId {
                
                var _beacon: NLBeacon? = nil
                
                // Search for the right beacon
                for (rid, b) in self.beacons {
                    if b == beacon as CLBeacon {
                        _beacon = b
                        break
                    }
                }
                
                if _beacon != nil {
                    let beaconRid = _beacon!.rid
                    
                    self.net.publish("location/resource/update", message: [
                        "rid": myRid,
                        "proximity": ["rid", beaconRid]
                        ])
                }
            }
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
        
        if requestName == "beacons" {
            if let r = response as? Dictionary<String, [AnyObject]> {
                if let beacons = response["beacons"] as? [Dictionary<String, AnyObject>] {
                    for beacon in beacons {
                        if let uuid = beacon["uuid"] as? String {
                            if let minorS = beacon["minor"] as? String {
                                if let majorS = beacon["major"] as? String {
                                    if let minor = minorS.toInt() {
                                        if let major = majorS.toInt() {
                                            if let rid = beacon["rid"] as? String {
                                                var b = NLBeacon(uuid: uuid, minor: minor, major: major, rid: rid)
                                                self.beacons[rid] = b
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
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