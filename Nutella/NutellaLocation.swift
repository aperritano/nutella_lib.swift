//
//  NutellaLocation.swift
//  


import Foundation
import CoreLocation
import CoreBluetooth

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
        self.parameter = NLManagedResourceParameterManager(resource: resource, delegate: delegate)
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
    public var parameter: NLManagedResourceParameterManager
    
    public var parameters: [String] {
        var keys = [String]()
        if let resource = self.resource {
            for (key, _) in resource.parameters {
                keys.append(key)
            }
        }
        return keys
    }
    
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
    public var x, y: NLDiscrete
}

public enum NLDiscrete {
    case Number(Int)
    case Letter(Character)
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
                self.delegate?.updateResource(resource: resource)
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
                self.delegate?.updateResource(resource: resource)
            }
        }
    }
}

/**
    Manages the discrete coordinate of a resource
*/
public class NLManagedResourceDiscrete: NLManaged {
    public var x: NLDiscrete? {
        get {
            return self.resource?.discrete?.x
        }
        set(x) {
            self.resource?.discrete?.x = x!
            if let resource = self.resource {
                self.delegate?.updateResource(resource: resource)
            }
        }
    }
    public var y: NLDiscrete? {
        get {
            return self.resource?.discrete?.y
        }
        set(y) {
            self.resource?.discrete?.y = y!
            if let resource = self.resource {
                self.delegate?.updateResource(resource: resource)
            }
        }
    }
}

public struct NLResourceProximity {
    var rid: String
    var distance: Double
}

public class NLManagedResourceParameterManager: NLManaged {
    public subscript(key: String) -> String? {
        get {
            return self.resource?.parameters[key]
        }
        set(newValue) {
            self.resource?.parameters[key] = newValue
            if let resource = self.resource {
                self.delegate?.updateResource(resource: resource)
            }
        }
    }
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
        let resource = self.resources[rid]
        if resource == nil {
            return nil
        }
        return NLManagedResource(resource: resource!, delegate: self.delegate)
    }
    
    weak var delegate: NLManagedResourceDelegate?
}

func == (left: NLBeacon, right: CLBeacon) -> Bool {
    return left.uuid.lowercased() == right.proximityUUID.uuidString.lowercased() &&
        left.minor == right.minor &&
        left.major == right.major
}

/**
    This class enables the communication with RoomPlaces module
*/
public class NutellaLocation: NSObject, NutellaNetDelegate, CLLocationManagerDelegate, NLManagedResourceDelegate, CBPeripheralDelegate {
    
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
                    
                    self.stopMonitoring()
                    self.stopVirtualBeacon()
                    
                    // STATIC => MONITORING
                    if self._resource?.type == NLResourceType.STATIC {
                        self.startMonitorning()
                    }
                    // DYNAMIC && iBeacon => VIRTUAL BEACON
                    if self._resource?.type == NLResourceType.DYNAMIC && self._resource?.trackingSystem == NLResourceTrackingSystem.PROXIMITY {
                        self.startVirtualBeacon()
                        self.startMonitorning()
                    }
                    
                }
            }
        }
    }
    
    var beacons = [String:NLBeacon]()
    var regions = [CLBeaconRegion]()
    let locationManager = CLLocationManager()
    let peripheralManager = CBPeripheralManager(delegate: nil, queue: DispatchQueue.global(attributes: .qosDefault))
    
    var resources: [String] {
        get {
            var resourceArray = [String]()
            for (key, _) in self.resource.resources {
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
    
    var beaconListDownloaded = false
    public func downloadBeaconList() {
        // Download the list of beacons from beacon-cloud-bot
        self.net.asyncRequest(channel: "beacon/beacons", message: [:], requestName: "beacons")
    }
    
    var resourceListDownloaded = false
    public func downloadResourceList() {
        // Download the list of resources from room-places-bot
        self.net.asyncRequest(channel: "location/resources", message: [:], requestName: "resources")
    }
    
    var subscribedToResources = false
    public func subscribeResourceUpdate() {
        // Subscribe to all resource update
        self.net.subscribe(channel: "location/resources/updated");
        self.net.subscribe(channel: "location/resource/static/#");
        
        // Subscribe to beacon and virtual beacon update
        self.net.subscribe(channel: "beacon/beacons/added");
        
        subscribedToResources = true
        
        self.checkReady()
    }
    
    public func startMonitoringRegions(uuids: [String]) {
        for uuid in uuids {
            let region: CLBeaconRegion = CLBeaconRegion(proximityUUID: NSUUID(uuidString: uuid)! as UUID, identifier: uuid)
            self.locationManager.startRangingBeacons(in: region)
            self.regions.append(region)
        }
        
        // Hardcoded region for virtual beacons
        let uuid = "00000000-0000-0000-0000-000000000000"
        let region: CLBeaconRegion = CLBeaconRegion(proximityUUID: NSUUID(uuidString: uuid)! as UUID, identifier: uuid)
        self.locationManager.startRangingBeacons(in: region)
        self.regions.append(region)
    }
    
    public func startMonitorning() {
        // Request the beacon cloud service for the uuids list
        
        self.net.asyncRequest(channel: "beacon/uuids", message: [:], requestName: "uuids")
    }
    
    public func stopMonitoring() {
        for region in self.regions {
            self.locationManager.stopMonitoring(for: region)
        }
        self.regions = []
    }
    
    public func startVirtualBeacon() {
        if let rid = self._resource?.rid {
            self.net.asyncRequest(channel: "beacon/virtual_beacon", message: ["rid": rid], requestName: "virtual_beacon")
        }
    }
    
    public func startVirtualBeacon(major: Int, minor: Int) {
        /*
        if peripheralManager.state.rawValue < CBPeripheralManagerState.PoweredOn.rawValue {
            println("WARNING: Bluetooth disabled")
        }
        */
        
        // Create the region
        let uuid = NSUUID(uuidString: "00000000-0000-0000-0000-000000000000")
        let region = CLBeaconRegion(proximityUUID: uuid! as UUID, major: UInt16(major), minor: UInt16(minor), identifier: "virtual_beacon")
        
        //fuck up
        let peripheralData : NSMutableDictionary = region.peripheralData(withMeasuredPower: -59)
        let dict = peripheralData as NSDictionary as! [String : AnyObject]
        peripheralManager.startAdvertising(dict)
//        if let peripheralData = region.peripheralDataWithMeasuredPower(-59) {
//            peripheralManager.startAdvertising(peripheralData as [NSObject : AnyObject])
//        }
    }
    
    public func stopVirtualBeacon() {
        peripheralManager.stopAdvertising()
    }
    
    // MARK: CLLocationManagerDelegate
    
    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {

        
        var updatedResources = [Dictionary<String,AnyObject>]()
        
        for clBeacon in beacons {
            print(clBeacon.proximityUUID);
            print(clBeacon.major);
            print(clBeacon.minor);
            print(clBeacon.proximity);
            print(clBeacon.accuracy);
            
            // If resourceId is not null
            if let myRid = self.configDelegate?.resourceId {
                
                var beacon: NLBeacon? = nil
                
                // Search for the right beacon
                for (_, b) in self.beacons {
                    if b == clBeacon {
                        beacon = b
                        break
                    }
                }
                
                if beacon != nil {
            
                    let distance = self.calculateDistance(clBeacon: (clBeacon))
                    
                    if distance < 0 {
                        continue
                    }
                    
                    // If the beacon is associated to a resource
                    if let resource = beacon!.resource {
                        if let clientResource = self._resource {
                            var updatedResource = [String:AnyObject]()
                            
                            if(clientResource.type == NLResourceType.STATIC &&
                               resource.type == NLResourceType.DYNAMIC) {
                                
                                    updatedResource["rid"] = beacon!.rid
                                    updatedResource["proximity"] = [
                                        "rid": myRid,
                                        "distance": distance
                                    ]
                                    /*
                                    self.net.publish("location/resource/update", message: [
                                        "rid": beacon!.rid,
                                        "proximity": ["rid": myRid,
                                            "distance": distance
                                        ]
                                        ])
                                    */
                            }
                            else if(clientResource.type == NLResourceType.DYNAMIC &&
                                    resource.type == NLResourceType.STATIC) {
                                    updatedResource["rid"] = myRid
                                    updatedResource["proximity"] = [
                                        "rid": beacon!.rid,
                                        "distance": distance
                                    ]
                                    /*
                                    self.net.publish("location/resource/update", message: [
                                        "rid": myRid
                                        ,
                                        "proximity": ["rid": beacon!.rid,
                                            "distance": distance
                                        ]
                                        ])
                                    */
                            }
                            
                            updatedResources.append(updatedResource)
                        }
                    }
                }
            }
        }
        
        if updatedResources.count > 0 {
            self.net.publish(channel: "location/resources/update", message: [
                "resources": updatedResources
            ])

        }
    }
    
    /**
        This is the algorithm for estimating the distance
    */
    func calculateDistance(clBeacon: CLBeacon) -> Double {
        let accuracy = clBeacon.accuracy
        //var distance = 0.0
        
        _ = 0.9
        _ = 0.1
        
        if accuracy < 0 {
            return -1
        }
        
        switch(clBeacon.proximity) {
            case CLProximity.immediate:
                if accuracy < 0.2 {
                    //distance = accuracy
                }
                else {
                   // distance = 0.1
                }
            case CLProximity.near:
                if accuracy < 2.0 {
                   // distance = accuracy
                }
                else {
                    //distance = 1.0 * proximityWeight + accuracy * accuracyWeight
                }
            case CLProximity.far:
                if accuracy > 2.0 {
                    //distance = accuracy
                }
                else {
                    //distance = 2.0 * proximityWeight + accuracy * accuracyWeight
                }
            case CLProximity.unknown: break
                //distance = accuracy
        }
        
        //return distance
        return accuracy;
    }
    
    func updateResource(resource: Dictionary<String, AnyObject>) {
        if let rid = resource["rid"] as? String {
            if let type = resource["type"] as? String {
                if let model = resource["model"] as? String {
                    if (resource["parameters"] as? Dictionary<String, AnyObject>) != nil {
                        var r = self.resource.resources[rid]
                        
                        if r == nil {
                            r = NLResource(rid: rid)
                            self.resource.resources[rid] = r
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
                            var _x: NLDiscrete? = nil,
                                _y: NLDiscrete? = nil
                            
                            if let x = discrete["x"] as? Double {
                                _x = .Number(Int(x))
                            }
                            else if let x = discrete["x"] as? String {
                                _x = .Letter(x[x.startIndex])
                            }
                            
                            if let y = discrete["y"] as? Double {
                                _y = .Number(Int(y))
                            }
                            else if let y = discrete["y"] as? String {
                                _y = .Letter(y[y.startIndex])
                            }
                        
                            if _x != nil && _y != nil {
                                r!.discrete = NLResourceDiscrete(x: _x!, y: _y!)
                            }
                        }
                        
                        if let proximity = resource["proximity"] as? Dictionary<String, AnyObject> {
                            r!.trackingSystem = NLResourceTrackingSystem.PROXIMITY
                            
                            if ((proximity["rid"] as? String) != nil) {
                                if let distance = proximity["distance"] as? Double {
                                    r!.proximity = NLResourceProximity(rid: rid, distance: distance)
                                }
                            }
                          
                        }
                        
                        // Update resource parameters
                        if let parameters = resource["parameters"] as? Dictionary<String, String> {
                            r!.parameters = parameters
                        }
                        
                        // Search the corresponding beacon and connect it
                        if let beacon = self.beacons[rid] {
                            beacon.resource = r!
                            r!.beacon = beacon
                        }
                        
                        // Set the resource type of the client
                        if let resourceId = self.resourceId {
                            if resourceId == rid {
                                self._resource = r!
                            }
                        }
                        
                        // Update the resource if updates enabled
                        if r?.notifyUpdate == true {
                            self.delegate?.resourceUpdated(resource: NLManagedResource(resource: r!, delegate: self))
                        }
                    }
                }
            }
        }
    }
    
    public func checkReady() {
        if(beaconListDownloaded && resourceListDownloaded && subscribedToResources) {
            let backgroundQueue = OperationQueue()
            backgroundQueue.addOperation(){
                self.delegate?.ready()
            }
        }
    }
    
    // MARK: NutellaNetDelegate
    public func messageReceived(channel: String, message: AnyObject, componentId: String?, resourceId: String?) {
        // Resource update
        if channel == "location/resources/updated" {
            if let resources = message["resources"] as? [Dictionary<String, AnyObject>] {
                for resource in resources {
                    updateResource(resource: resource)
                }
            }
        }
        
        // Resource enter
        
        if channel.range(of: "^location/resource/static/.*/enter$", options: .regularExpression) != nil {
            
            //  let r = channel.startIndex.advancedBy(25)..<channel.endIndex.advancedBy(-6)
            
            
            let i1 = channel.index(channel.startIndex, offsetBy: 25)
            let i2 = channel.index(channel.endIndex, offsetBy: -6)
            let r = i1..<i2
            
            
            let baseStationRid = channel[r]
            
            // Update the resources
            if let resources = message["resources"] as? [Dictionary<String, AnyObject>] {
                for resource in resources {
                    updateResource(resource: resource)
                    if let rid = resource["rid"] as? String {
                        let dynamicResource = self.resource.resources[rid]
                        let staticResource = self.resource.resources[baseStationRid]
                        
                        if dynamicResource != nil && staticResource !=  nil && staticResource?.notifyEnter == true {
                            self.delegate?.resourceEntered(dynamicResource: NLManagedResource(resource: dynamicResource!, delegate: self),
                                staticResource: NLManagedResource(resource: staticResource!, delegate: self))
                        }
                    }
                }
            }
        }
        
        // Resource exit
        if channel.range(of: "^location/resource/static/.*/exit$", options: .regularExpression) != nil {
            

            
            let i1 = channel.index(channel.startIndex, offsetBy: 25)
            let i2 = channel.index(channel.endIndex, offsetBy: -5)
            let r = i1..<i2
            
             let baseStationRid = channel[r]
            
            // Update the resources
            if let resources = message["resources"] as? [Dictionary<String, AnyObject>] {
                for resource in resources {
                    updateResource(resource: resource)
                    if let rid = resource["rid"] as? String {
                        let dynamicResource = self.resource.resources[rid]
                        let staticResource = self.resource.resources[baseStationRid]
                        
                        if dynamicResource != nil && staticResource !=  nil && staticResource?.notifyExit == true {
                            self.delegate?.resourceExited(dynamicResource: NLManagedResource(resource: dynamicResource!, delegate: self),
                                staticResource: NLManagedResource(resource: staticResource!, delegate: self))
                        }
                    }
                }
            }
        }
        
        // Beacon or virtual beacon added
        if channel == "beacon/beacons/added" {
            if let beacons = message["beacons"] as? [Dictionary<String, AnyObject>] {
                for beacon in beacons {
                    if let uuid = beacon["uuid"] as? String {
                        if let minorS = beacon["minor"] as? String {
                            if let majorS = beacon["major"] as? String {
                                if let minor = Int(minorS) {
                                    if let major = Int(majorS) {
                                        if let rid = beacon["rid"] as? String {
                                            let b = NLBeacon(uuid: uuid,
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
    
    public func responseReceived(channelName: String, requestName: String?, response: AnyObject) {
        if requestName == "uuids" {
            if response is Dictionary<String, [String]> {
                if let uuids = response["uuids"] as? [String] {
                    self.startMonitoringRegions(uuids: uuids)
                }
            }
        }
        if requestName == "beacons" {
            if response is Dictionary<String, [AnyObject]> {
                if let beacons = response["beacons"] as? [Dictionary<String, AnyObject>] {
                    for beacon in beacons {
                        if let uuid = beacon["uuid"] as? String {
                            if let minorS = beacon["minor"] as? String {
                                if let majorS = beacon["major"] as? String {
                                    if let minor = Int(minorS) {
                                        if let major = Int(majorS) {
                                            if let rid = beacon["rid"] as? String {
                                                let b = NLBeacon(uuid: uuid,
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
            beaconListDownloaded = true
            self.checkReady()
        }
        
        if requestName == "resources" {
            if response is Dictionary<String, [AnyObject]> {
                if let resources = response["resources"] as? [Dictionary<String, AnyObject>] {
                    for resource in resources {
                        updateResource(resource: resource)
                    }
                }
            }
            resourceListDownloaded = true
            self.checkReady()
        }
        
        if requestName == "virtual_beacon" {
            if let r = response as? Dictionary<String, AnyObject> {
                if let minorS = r["minor"] as? String {
                    if let majorS = r["major"] as? String {
                        if let minor = Int(minorS) {
                            if let major = Int(majorS) {
                                print(minor);
                                self.startVirtualBeacon(major: major, minor: minor)
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
        
        self.net.publish(channel: "location/resource/update",
            message: message)
    }

}

extension String {
    func nsRange(from range: Range<String.Index>) -> NSRange {
        let utf16view = self.utf16
        let from = range.lowerBound.samePosition(in: utf16view)
        let to = range.upperBound.samePosition(in: utf16view)
        return NSMakeRange(utf16view.distance(from: utf16view.startIndex, to: from),
                           utf16view.distance(from: from, to: to))
    }
}

