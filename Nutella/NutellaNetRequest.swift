//
//  NutellaNetRequest.swift
//  

import Foundation

struct NutellaNetRequest {
    var channel: String
    var id: Int
    var name: String?
    var message: AnyObject
    
    init(channel: String, id: Int, name: String?, message: AnyObject) {
        self.channel = channel
        self.id = id
        self.name = name
        self.message = message
    }
}
