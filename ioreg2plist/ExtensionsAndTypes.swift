//
//  Extensions.swift
//  ioreg2plist
//
//  Created by ITzTravelInTime on 15/02/22.
//

import Foundation
import TINUSerialization

enum MatchType{
    case all
    case nodeNameOnly
    case namePropertyOnly
    
    var checkEntryName: Bool{
        return self == .all || self == .nodeNameOnly
    }
    
    var checkNameProperty: Bool{
        return self == .all || self == .namePropertyOnly
    }
}

typealias ReturnType = [String: Any]

extension Dictionary: FastEncodable where Key == String, Value == ReturnType {
    
}

extension Dictionary: GenericEncodable where Key == String, Value == ReturnType{
    
}

extension Array: FastEncodable where Element == ReturnType {
    
}

extension Array: GenericEncodable where Element == ReturnType{
    
}
