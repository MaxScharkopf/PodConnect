//
//  LocationManager.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 3/9/26.
//
import Foundation
import CoreLocation
import Combine
import FirebaseFirestore
import FirebaseAuth

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    private let manager = CLLocationManager()
    private var liveLocationRepository: LiveLocationRepository?
    private var activeReceiverUid: String?
    private var activeOwnerUid: String?
    private var activeOwnerUsername: String?
    private var lastUploadTime: Date?

    @Published var isSharingLiveLocation = false
    @Published var userLocation: CLLocationCoordinate2D? = nil
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    private let campusRegion = CLCircularRegion(
        center: CLLocationCoordinate2D(latitude: 34.1647, longitude: -119.0426),
        radius: 900,
        identifier: "csuci-campus"
    )

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        userLocation = location.coordinate

        guard isSharingLiveLocation else { return }

        let now = Date()

        if let lastUploadTime,
           now.timeIntervalSince(lastUploadTime) < 10 {
            return
        }

        lastUploadTime = now

        Task {
            await uploadLiveLocation(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func startLiveLocationSharing(
        receiverUid: String,
        ownerUid: String,
        ownerUsername: String,
        liveLocationRepository: LiveLocationRepository
    ) {
        self.activeReceiverUid = receiverUid
        self.activeOwnerUid = ownerUid
        self.activeOwnerUsername = ownerUsername
        self.liveLocationRepository = liveLocationRepository
        self.isSharingLiveLocation = true

        requestLocationPermission()
        startCampusGeofence()
        manager.startUpdatingLocation()
        if let coordinate = userLocation {
            let location = CLLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )

            Task {
                await uploadLiveLocation(location)
            }
        }
    }

    func stopLiveLocationSharing() {
        let ownerUid = activeOwnerUid
        let receiverUid = activeReceiverUid
        let repository = liveLocationRepository

        isSharingLiveLocation = false
        manager.stopMonitoring(for: campusRegion)
        activeReceiverUid = nil
        activeOwnerUid = nil
        activeOwnerUsername = nil
        lastUploadTime = nil

        Task {
            if let ownerUid, let receiverUid, let repository {
                try? await repository.stopShare(
                    ownerUid: ownerUid,
                    receiverUid: receiverUid
                )
            }
        }
    }
    
    func requestLocationPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard region.identifier == campusRegion.identifier else { return }
        stopLiveLocationSharing()
    }
    
    private func uploadLiveLocation(_ location: CLLocation) async {
        guard
            let repository = liveLocationRepository,
            let ownerUid = activeOwnerUid,
            let ownerUsername = activeOwnerUsername,
            let receiverUid = activeReceiverUid
        else { return }

        let share = LiveLocationShare(
            id: "\(ownerUid)_\(receiverUid)",
            ownerUid: ownerUid,
            ownerUsername: ownerUsername,
            receiverUid: receiverUid,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            isActive: true,
            updatedAt: Timestamp(date: Date())
        )

        do {
            try await repository.startOrUpdateShare(share)
        } catch {
            print("Failed to update live location:", error)
        }
    }

    private func startCampusGeofence() {
        campusRegion.notifyOnExit = true
        campusRegion.notifyOnEntry = false

        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            manager.startMonitoring(for: campusRegion)
        }
    }
}
