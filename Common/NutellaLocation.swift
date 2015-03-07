//
//  NutellaLocation.swift
//  
//
//  Created by Gianluca Venturini on 24/01/15.
//
//

import Foundation
import CoreLocation

class NLBeacon {
    init(uuid: String,
        minor: Int,
        major: Int,
        rid: String) {
            self.uuid = uuid
            self.minor = minor
            self.major = major
            self.rid = rid
    }
    
    
    var uuid: String
    var minor: Int
    var major: Int
    var rid: String
    weak var resource: NLResource?
}

class NLResource {
    init(type: NLResourceType,
        trackingSystem: NLResourceTrackingSystem,
        rid: String) {
            self.type = type
            self.trackingSystem = trackingSystem
            self.rid = rid
    }
    convenience init(rid: String) {
        self.init(type: NLResourceType.UNKNOWN,
            trackingSystem: NLResourceTrackingSystem.NONE,
            rid: rid)
    }
    var type: NLResourceType
    var trackingSystem: NLResourceTrackingSystem
    var rid: String
    weak var beacon: NLBeacon?
}

enum NLResourceType {
    case STATIC
    case DYNAMIC
    case UNKNOWN
}

enum NLResourceTrackingSystem {
    case CONTINUOUS
    case DISCRETE
    case PROXIMITY
    case NONE
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
    
    var _resourceId: String?
    var resourceId: String? {
        get {
            return self._resourceId
        }
        set(resourceId) {
            self._resourceId = resourceId
            if resourceId != nil {
                if let resource = self.resources[resourceId!] {
                    self.resource = resource
                }
            }
        }
    }
    
    var beacons = [String:NLBeacon]()
    var resources = [String:NLResource]()
    
    var regions = [CLBeaconRegion]()
    
    let locationManager = CLLocationManager()
    
    // Resource associated with nutella client
    var resource: NLResource?
    
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
        // Download the list of beacons from beacon-cloud-bot
        self.net.asyncRequest("beacon/beacons", message: [:], requestName: "beacons")
    }
    
    public func downloadResourceList() {
        // Download the list of resources from room-places-bot
        self.net.asyncRequest("location/resources", message: [:], requestName: "resources")
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
        for clBeacon in didRangeBeacons {
            println(clBeacon.proximityUUID);
            println(clBeacon.major);
            println(clBeacon.minor);
            println(clBeacon.proximity);
            println(clBeacon.accuracy);
            
            // If resourceId is not null
            if let myRid = self.configDelegate?.resourceId {
                
                var beacon: NLBeacon? = nil
                
                // Search for the right beacon
                for (rid, b) in self.beacons {
                    if b == clBeacon as CLBeacon {
                        beacon = b
                        break
                    }
                }
                
                if beacon != nil {
                    let distance = (clBeacon as CLBeacon).accuracy
                    
                    // If the beacon is associated to a resource
                    if let resource = beacon!.resource {
                        if let clientResource = self.resource {
                            if(clientResource.type == NLResourceType.STATIC &&
                               resource.type == NLResourceType.DYNAMIC) {
                                    println("Send beacon update");
                                    self.net.publish("location/resource/update", message: [
                                        "rid": beacon!.rid,
                                        "proximity": ["rid": myRid,
                                            "distance": distance
                                        ]
                                        ])
                            }
                            else if(clientResource.type == NLResourceType.DYNAMIC &&
                                    resource.type == NLResourceType.STATIC) {
                                    self.net.publish("location/resource/update", message: [
                                        "rid": myRid
                                        ,
                                        "proximity": ["rid": beacon!.rid,
                                            "distance": distance
                                        ]
                                        ])
                            }
                        }
                    }
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
                                                var b = NLBeacon(uuid: uuid,
                                                    minor: minor,
                                                    major: major,
                                                    rid: rid)
                                                self.beacons[rid] = b
                                                
                                                if let resource = self.resources[rid] {
                                                    b.resource = resource
                                                    resource.beacon = b
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
        
        if requestName == "resources" {
            if let r = response as? Dictionary<String, [AnyObject]> {
                if let resources = response["resources"] as? [Dictionary<String, AnyObject>] {
                    for resource in resources {
                        if let rid = resource["rid"] as? String {
                            if let type = resource["type"] as? String {
                                var newResource = NLResource(rid: rid)
                                if let tracking = resource["continuous"] as? Dictionary<String, AnyObject> {
                                    newResource.trackingSystem = NLResourceTrackingSystem.CONTINUOUS;
                                }
                                if let tracking = resource["discrete"] as? Dictionary<String, AnyObject> {
                                    newResource.trackingSystem = NLResourceTrackingSystem.DISCRETE;
                                }
                                if let tracking = resource["proximity"] as? Dictionary<String, AnyObject> {
                                    newResource.trackingSystem = NLResourceTrackingSystem.PROXIMITY;
                                }
                                if let type = resource["type"] as? String {
                                    if(type == "STATIC") {
                                        newResource.type = NLResourceType.STATIC
                                    }
                                    else if(type == "DYNAMIC") {
                                        newResource.type = NLResourceType.DYNAMIC
                                    }
                                }
                                self.resources[rid] = newResource
                                
                                // Search the corresponding beacon and connect it
                                if let beacon = self.beacons[rid] {
                                    beacon.resource = newResource
                                    newResource.beacon = beacon
                                }
                                
                                // Set the resource type of the client
                                if let resourceId = self.resourceId {
                                    if resourceId == rid {
                                        self.resource = newResource
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