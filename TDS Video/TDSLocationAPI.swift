//
//  TDSLocationAPI.swift
//  TDS Video
//
//  Created by Thomas Dye on 17/03/2025.
//

import Foundation
import CoreLocation
import SwiftUI
class TDSLocationAPI: NSObject, CLLocationManagerDelegate,ObservableObject {
    static let shared = TDSLocationAPI()
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    private var lastSentLocation: CLLocation?
    private let stationaryDistanceThreshold: CLLocationDistance = 50  // 10 m

    // NEW: track whether updates are currently active
    @Published  var isUpdatingLocation = false
    
    // NEW: track whether user is currently considered “stationary”
    @Published var isStationary = true

//    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
//
    var latitude: Double? { currentLocation?.coordinate.latitude }
    var longitude: Double? { currentLocation?.coordinate.longitude }
//
//    var Access:Bool = true
//    private override init() {
//        super.init()
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.startUpdatingLocation()
//        if TDSCarplayAccess.shared.DisableIsStationary == true {
//            isStationary = true
//        }
//    }
//
//    func requestLocationPermission() {
//        locationManager.requestWhenInUseAuthorization()
//    }
//
//    
//    func CombinedValue() -> Bool {
//        if TDSCarplayAccess.shared.DisableIsStationary == true {
//            return true
//        }
//        if isUpdatingLocation == false {
//            return false
//        }
//       if isStationary == false {
//           return false
//        }
//        return true
//    }
//    @MainActor
//    func startUpdatingLocation() {
//        guard CLLocationManager.locationServicesEnabled() else { return }
//        lastSentLocation = nil
//
//        isStationary = false
//        isUpdatingLocation = true
//        locationManager.startUpdatingLocation()
//        if TDSCarplayAccess.shared.DisableIsStationary == true {
//            isStationary = true
//        }
//    }
//    @MainActor
//    func stopUpdatingLocation() {
//        locationManager.stopUpdatingLocation()
//        isUpdatingLocation = false
//    }
//
//    /// Returns a tuple of (updating, stationary)
//    func currentMovementStatus() -> (updating: Bool, stationary: Bool) {
//        return (isUpdatingLocation, isStationary)
//    }
//
//    // MARK: - CLLocationManagerDelegate
//    @MainActor
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let newLoc = locations.last else { return }
//
//        currentLocation = newLoc
//
//        if let last = lastSentLocation {
//            let distanceMoved = newLoc.distance(from: last)
//            if distanceMoved < stationaryDistanceThreshold {
//                // still within threshold → stationary
//                isStationary = true
//                // keep updating until movement detected
//                return
//            } else {
//                // moved beyond threshold → not stationary
//                if TDSCarplayAccess.shared.DisableIsStationary == true {
//                    isStationary = false
//                }
//            }
//        }
//
//        // first fix or moved enough to count as “non‑stationary”
//        lastSentLocation = newLoc
//        locationContinuation?.resume(returning: newLoc)
//        locationContinuation = nil
//        stopUpdatingLocation()
//    }
//
//    @MainActor
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("Failed to get location: \(error.localizedDescription)")
//        locationContinuation?.resume(returning: nil)
//        locationContinuation = nil
//        stopUpdatingLocation()
//    }
}

