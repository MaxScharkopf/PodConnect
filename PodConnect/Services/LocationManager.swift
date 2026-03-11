//
//  LocationManager.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 3/9/26.
//
import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }
}
