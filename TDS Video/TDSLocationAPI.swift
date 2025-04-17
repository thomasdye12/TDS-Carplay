//
//  TDSLocationAPI.swift
//  TDS Video
//
//  Created by Thomas Dye on 17/03/2025.
//

import Foundation
import CoreLocation

import Foundation
import CoreLocation

class TDSLocationAPI: NSObject, CLLocationManagerDelegate {
    static let shared = TDSLocationAPI()
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    var latitude: Double? {
        return currentLocation?.coordinate.latitude
    }
    
    var longitude: Double? {
        return currentLocation?.coordinate.longitude
    }

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }




    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
        stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
        stopUpdatingLocation()
    }
}
