//
//  Dictionary.swift
//  
//
//  Created by Gianluca Venturini on 23/01/15.
//
//

import Foundation

extension Dictionary {    
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}
