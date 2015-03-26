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
    init(model: NLResourceModel,
        type: NLResourceType,
        trackingSystem: NLResourceTrackingSystem,
        rid: String,
        parameters: Dictionary<String,String>) {
            self.model = model
            self.type = type
            self.trackingSystem = trackingSystem
            self.rid = rid
            self.parameters = parameters
            
            self.notifyUpdate = false
            self.notifyEnter = false
            self.notifyExit = false
    }
    convenience init(rid: String) {
        self.init(model: NLResourceModel.UNKNOWN,
            type: NLResourceType.UNKNOWN,
            trackingSystem: NLResourceTrackingSystem.NONE,
            rid: rid,
            parameters: Dictionary<String,String>())
    }
    var model: NLResourceModel
    var type: NLResourceType
    var trackingSystem: NLResourceTrackingSystem
    var rid: String
    var parameters: [String:String]
    weak var beacon: NLBeacon?
    
    // Satates that when an update is received the NutellaLocationDelegate must be notified of it
    var notifyUpdate: Bool
    
    // Satates that when a resource enter/exit the range the NutellaLocationDelegate must be notified of it
    var notifyEnter: Bool
    var notifyExit: Bool
    
    // Resource coordinates
    var continuous: NLResourceContinuous?
    var discrete: NLResourceDiscrete?
    var proximity: NLResourceProximity?
}

/**
    This class manages part of a resource and keep it synchronized with the server
*/
public class NLManaged {
    weak var delegate: NLManagedResourceDelegate?
    weak var resource: NLResource?
    
    init(resource: NLResource, delegate: NLManagedResourceDelegate?) {
        self.resource = resource
        self.delegate = delegate
    }
}

/**
    This class manages a resource and keep it synchronized with the server, it exposes the right permission for every part of the resource
*/
public class NLManagedResource: NLManaged {
    
    override init(resource: NLResource, delegate: NLManagedResourceDelegate?) {
        self.continuous = NLManagedResourceContinuous(resource: resource, delegate: delegate)
        self.discrete = NLManagedResourceDiscrete(resource: resource, delegate: delegate)
        super.init(resource: resource, delegate: delegate)
    }
    
    override var delegate: NLManagedResourceDelegate? {
        get {
            return super.delegate
        }
        set(delegate) {
            super.delegate = delegate
            self.continuous.delegate = delegate
            self.discrete.delegate = delegate
        }
    }
    
    // Expose all the properties of NLResource using the right permissions
    public var model: NLResourceModel? {
        return self.resource?.model
    }
    public var type: NLResourceType? {
        return self.resource?.type
    }
    public var rid: String? {
        return self.resource?.rid
    }
    public var trackingSystem: NLResourceTrackingSystem? {
        return self.resource?.trackingSystem
    }
    public var continuous: NLManagedResourceContinuous
    public var discrete: NLManagedResourceDiscrete
    
    public var notifyUpdate: Bool? {
        get {
            return resource?.notifyUpdate
        }
        set(notifyUpdate) {
            resource?.notifyUpdate = notifyUpdate!
        }
    }
    
    public var notifyEnter: Bool? {
        get {
            return resource?.notifyEnter
        }
        set(notifyEnter) {
            resource?.notifyEnter = notifyEnter!
        }
    }
    
    public var notifyExit: Bool? {
        get {
            return resource?.notifyExit
        }
        set(notifyExit) {
            resource?.notifyExit = notifyExit!
        }
    }
}

protocol NLManagedResourceDelegate : class {
    func updateResource(resource: NLResource)
}

/**
    Model of a resource
*/
public enum NLResourceModel {
    case IMAC
    case IPHONE
    case IPAD
    case IBEACON
    case UNKNOWN
}

/**
    Type of resource
*/
public enum NLResourceType {
    case STATIC
    case DYNAMIC
    case UNKNOWN
}

/**
    Tracking system type
*/
public enum NLResourceTrackingSystem {
    case CONTINUOUS
    case DISCRETE
    case PROXIMITY
    case NONE
}

public struct NLResourceContinuous {
    public var x, y: Double
}

public struct NLResourceDiscrete {
    public var x, y: Double
}

/**
    Manages the continuous coordinate of a resource
*/
public class NLManagedResourceContinuous: NLManaged {
    public var x: Double? {
        get {
            return self.resource?.continuous?.x
        }
        set(x) {
            self.resource?.continuous?.x = x!
            if let resource = self.resource {
                self.delegate?.updateResource(resource)
            }
        }
    }
    public var y: Double? {
        get {
            return self.resource?.continuous?.y
        }
        set(y) {
            self.resource?.continuous?.y = y!
            if let resource = self.resource {
                self.delegate?.updateResource(resource)
            }
        }
    }
}

/**
    Manages the discrete coordinate of a resource
*/
public class NLManagedResourceDiscrete: NLManaged {
    public var x: Double? {
        get {
            return self.resource?.discrete?.x
        }
        set(x) {
            self.resource?.discrete?.x = x!
            if let resource = self.resource {
                self.delegate?.updateResource(resource)
            }
        }
    }
    public var y: Double? {
        get {
            return self.resource?.discrete?.y
        }
        set(y) {
            self.resource?.discrete?.y = y!
            if let resource = self.resource {
                self.delegate?.updateResource(resource)
            }
        }
    }
}

public struct NLResourceProximity {
    var rid: String
    var distance: Double
}

/**
    Manages all the resources and keep them accessible to the client
*/
public class NLResourceManager {
    var resources = [String:NLResource]()
    
    init(delegate: NLManagedResourceDelegate? = nil) {
        self.delegate = delegate
    }
    
    public subscript(rid: String) -> NLManagedResource? {
        var resource = self.resources[rid]
        if resource == nil {
            return nil
        }
        return NLManagedResource(resource: resource!, delegate: self.delegate)
    }
    
    weak var delegate: NLManagedResourceDelegate?
}

func == (left: NLBeacon, right: CLBeacon) -> Bool {
    return left.uuid.lowercaseString == right.proximityUUID.UUIDString.lowercaseString &&
        left.minor == right.minor &&
        left.major == right.major
}

/**
    This class enables the communication with RoomPlaces module
*/
public class NutellaLocation: NSObject, NutellaNetDelegate, CLLocationManagerDelegate, NLManagedResourceDelegate {
    
    var delegate: NutellaLocationDelegate?
    
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
                if let resource = self.resource.resources[resourceId!] {
                    self._resource = resource
                }
            }
        }
    }
    
    var beacons = [String:NLBeacon]()
    var regions = [CLBeaconRegion]()
    let locationManager = CLLocationManager()
    
    var resources: [String] {
        get {
            var resourceArray = [String]()
            for (key, resource) in self.resource.resources {
                resourceArray.append(key);
            }
            return resourceArray;
        }
    }
    
    /**
        Resource manager: enable the access to the resources
    */
    public var resource: NLResourceManager!
    
    // Resource associated with nutella client
    var _resource: NLResource?
    
    let net: NutellaNet
    
    init(locationServer: String) {
        
        // Initialize nutella net instance
        net = NutellaNet(host: locationServer, clientId: nil)
        
        super.init()
        
        // Initialize the resource manager
        resource = NLResourceManager(delegate: self)
        
        resource.delegate = self
        
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
    
    public func subscribeResourceUpdate() {
        // Subscribe to all resource update
        self.net.subscribe("location/resources/updated");
        self.net.subscribe("location/resource/static/#");
        
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
                    
                    if distance < 0 {
                        continue
                    }
                    
                    // If the beacon is associated to a resource
                    if let resource = beacon!.resource {
                        if let clientResource = self._resource {
                            if(clientResource.type == NLResourceType.STATIC &&
                               resource.type == NLResourceType.DYNAMIC) {
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
    
    func updateResource(resource: Dictionary<String, AnyObject>) {
        if let rid = resource["rid"] as? String {
            if let type = resource["type"] as? String {
                if let model = resource["model"] as? String {
                    if let parameters = resource["parameters"] as? Dictionary<String, AnyObject> {
                        var r = self.resource.resources[rid]
                        
                        if r == nil {
                            r = NLResource(rid: rid)
                        }
                        
                        switch(type) {
                        case "STATIC":
                            r!.type = NLResourceType.STATIC
                            break
                        case "DYNAMIC":
                            r!.type = NLResourceType.DYNAMIC
                            break
                        default:
                            r!.type = NLResourceType.UNKNOWN
                        }
                        
                        switch(model) {
                        case "IMAC":
                            r!.model = NLResourceModel.IMAC
                            break
                        case "IPHONE":
                            r!.model = NLResourceModel.IPHONE
                            break
                        case "IPAD":
                            r!.model = NLResourceModel.IPAD
                            break
                        case "IBEACON":
                            r!.model = NLResourceModel.IBEACON
                            break
                        default:
                            r!.model = NLResourceModel.UNKNOWN
                        }
                        
                        if let continuous = resource["continuous"] as? Dictionary<String, AnyObject> {
                            r!.trackingSystem = NLResourceTrackingSystem.CONTINUOUS
                            if let x = continuous["x"] as? Double {
                                if let y = continuous["y"] as? Double {
                                    r!.continuous = NLResourceContinuous(x: x, y: y)
                                }
                            }
                        }
                        
                        if let discrete = resource["discrete"] as? Dictionary<String, AnyObject> {
                            r!.trackingSystem = NLResourceTrackingSystem.DISCRETE
                            if let x = discrete["x"] as? Double {
                                if let y = discrete["y"] as? Double {
                                    r!.discrete = NLResourceDiscrete(x: x, y: y)
                                }
                            }
                        }
                        
                        if let proximity = resource["proximity"] as? Dictionary<String, AnyObject> {
                            r!.trackingSystem = NLResourceTrackingSystem.PROXIMITY
                            if let baseStationRid = proximity["rid"] as? String {
                                if let distance = proximity["distance"] as? Double {
                                    r!.proximity = NLResourceProximity(rid: rid, distance: distance)
                                }
                            }
                        }
                        
                        // Update the resource if updates enabled
                        if r?.notifyUpdate == true {
                            self.delegate?.resourceUpdated(NLManagedResource(resource: r!, delegate: self))
                        }
                    }
                }
            }
        }
    }
    
    
    
    // MARK: NutellaNetDelegate
    public func messageReceived(channel: String, message: AnyObject, componentId: String?, resourceId: String?) {
        // Resource update
        if channel == "location/resources/updated" {
            if let resources = message["resources"] as? [Dictionary<String, AnyObject>] {
                for resource in resources {
                    updateResource(resource)
                }
            }
        }
        
        // Resource enter
        if let match = channel.rangeOfString("^location/resource/static/.*/enter$", options: .RegularExpressionSearch) {
            let baseStationRid = channel.substringWithRange(Range<String.Index>(start: advance(channel.startIndex, 25), end: advance(channel.endIndex,-6)))
            
            // Update the resources
            if let resources = message["resources"] as? [Dictionary<String, AnyObject>] {
                for resource in resources {
                    updateResource(resource)
                    if let rid = resource["rid"] as? String {
                        let dynamicResource = self.resource.resources[rid]
                        let staticResource = self.resource.resources[baseStationRid]
                        
                        if dynamicResource != nil && staticResource !=  nil && staticResource?.notifyEnter == true {
                            self.delegate?.resourceEntered(NLManagedResource(resource: dynamicResource!, delegate: self),
                                staticResource: NLManagedResource(resource: staticResource!, delegate: self))
                        }
                    }
                }
            }
        }
        
        // Resource exit
        if let match = channel.rangeOfString("^location/resource/static/.*/exit$", options: .RegularExpressionSearch) {
            let baseStationRid = channel.substringWithRange(Range<String.Index>(start: advance(channel.startIndex, 25), end: advance(channel.endIndex,-5)))
            
            // Update the resources
            if let resources = message["resources"] as? [Dictionary<String, AnyObject>] {
                for resource in resources {
                    updateResource(resource)
                    if let rid = resource["rid"] as? String {
                        let dynamicResource = self.resource.resources[rid]
                        let staticResource = self.resource.resources[baseStationRid]
                        
                        if dynamicResource != nil && staticResource !=  nil && staticResource?.notifyExit == true {
                            self.delegate?.resourceExited(NLManagedResource(resource: dynamicResource!, delegate: self),
                                staticResource: NLManagedResource(resource: staticResource!, delegate: self))
                        }
                    }
                }
            }
        }
    }
    
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
                                                
                                                if let resource = self.resource.resources[rid] {
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
                            if let model = resource["model"] as? String {
                                if let type = resource["type"] as? String {
                                    var newResource = NLResource(rid: rid)
                                    if let continuous = resource["continuous"] as? Dictionary<String, AnyObject> {
                                        newResource.trackingSystem = NLResourceTrackingSystem.CONTINUOUS;
                                        if let x = continuous["x"] as? Double {
                                            if let y = continuous["y"] as? Double {
                                                newResource.continuous = NLResourceContinuous(x: x, y: y)
                                            }
                                        }
                                    }
                                    if let discrete = resource["discrete"] as? Dictionary<String, AnyObject> {
                                        newResource.trackingSystem = NLResourceTrackingSystem.DISCRETE;
                                        if let x = discrete["x"] as? Double {
                                            if let y = discrete["y"] as? Double {
                                                newResource.discrete = NLResourceDiscrete(x: x, y: y)
                                            }
                                        }
                                    }
                                    if let proximity = resource["proximity"] as? Dictionary<String, AnyObject> {
                                        newResource.trackingSystem = NLResourceTrackingSystem.PROXIMITY;
                                        if let baseStationRid = proximity["rid"] as? String {
                                            if let distance = proximity["distance"] as? Double {
                                                newResource.proximity = NLResourceProximity(rid: rid, distance: distance)
                                            }
                                        }
                                    }
                                    
                                    switch(type) {
                                    case "STATIC":
                                        newResource.type = NLResourceType.STATIC
                                        break
                                    case "DYNAMIC":
                                        newResource.type = NLResourceType.DYNAMIC
                                        break
                                    default:
                                        newResource.type = NLResourceType.UNKNOWN
                                    }
                                    
                                    switch(model) {
                                    case "IMAC":
                                        newResource.model = NLResourceModel.IMAC
                                        break
                                    case "IPHONE":
                                        newResource.model = NLResourceModel.IPHONE
                                        break
                                    case "IPAD":
                                        newResource.model = NLResourceModel.IPAD
                                        break
                                    case "IBEACON":
                                        newResource.model = NLResourceModel.IBEACON
                                        break
                                    default:
                                        newResource.model = NLResourceModel.UNKNOWN
                                    }
                                    
                                    self.resource.resources[rid] = newResource
                                    
                                    // Search the corresponding beacon and connect it
                                    if let beacon = self.beacons[rid] {
                                        beacon.resource = newResource
                                        newResource.beacon = beacon
                                    }
                                    
                                    // Set the resource type of the client
                                    if let resourceId = self.resourceId {
                                        if resourceId == rid {
                                            self._resource = newResource
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
    
    // MARK: NLManagedResourceDelegate
    
    // Update the resource on the server
    func updateResource(resource: NLResource) {
        var message: [String:AnyObject] = [
            "rid": resource.rid
        ]
        
        if resource.trackingSystem == NLResourceTrackingSystem.CONTINUOUS {
            message["continuous"] = [
                "x": resource.continuous!.x,
                "y": resource.continuous!.y]
        }
        
        self.net.publish("location/resource/update",
            message: message)
    }

}