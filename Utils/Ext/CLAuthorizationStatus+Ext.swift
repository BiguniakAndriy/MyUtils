//
//  CLAuthorizationStatus+Ext.swift
//  Utils
//
//  Created by Andriy Biguniak on 18.07.2025.
//

import CoreLocation


extension CLAuthorizationStatus: @retroactive CustomStringConvertible
{
    public var description: String {
        switch self {
            case .notDetermined:
                return "notDetermined"
            case .restricted:
                return "restricted"
            case .denied:
                return "denied"
            case .authorizedAlways:
                return "authorizedAlways"
            case .authorizedWhenInUse:
                return "authorizedWhenInUse"
            @unknown default:
                return "unknown"
        }
    }
}
