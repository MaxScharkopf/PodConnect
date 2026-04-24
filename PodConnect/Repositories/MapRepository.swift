//
//  MapRepository.swift
//  PodConnect
//
//  Created by Jacob Russell on 4/15/26.
//

import FirebaseFirestore
import Foundation
import CoreLocation
import FirebaseAuth

final class MapRepository {
    
    private let firestoreService: FirestoreService
    private var authService: AuthService
    private let pinsPath = "pins"
    
    init(firestoreService: FirestoreService, authService: AuthService) {
        self.firestoreService = firestoreService
        self.authService = authService
    }
    
    func fetchCurrentUserPins() async throws -> [MapPin] {
        guard let userId = Auth.auth().currentUser?.uid else {
            return []
        }

        let ownedPins: [MapPin] = try await firestoreService.fetchCollection(path: pinsPath) { collection in
            collection
                .whereField("pinType", isEqualTo: "user")
                .whereField("ownerUserId", isEqualTo: userId)
        }
        
        let sharedPins: [MapPin] = try await firestoreService.fetchCollection(path: pinsPath) { collection in
            collection
                .whereField("pinType", isEqualTo: "user")
                .whereField("sharedWith", arrayContains: userId)
        }
        
        let combinedPins = ownedPins + sharedPins
        
        var seenIDs = Set<String>()
        let uniquePins = combinedPins.filter { pin in
            guard let id = pin.id else { return true }
            if seenIDs.contains(id) {
                return false
            } else {
                seenIDs.insert(id)
                return true
            }
        }

        return uniquePins
    }
    
    func createUserPin(name: String, subtitle: String?, coordinate: CLLocationCoordinate2D, sharedWith: [String]) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "MapRepository",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "User not authenticated."]
            )
        }
            
        let pin = MapPin(
            id: nil,
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            category: "User Pin",
            subtitle: subtitle,
            pinType: "user",
            ownerUserId: userId,
            createdAt: Timestamp(date: Date()),
            sharedWith: sharedWith
        )
        
        try await firestoreService.saveDocument(path: pinsPath, data: pin)
    }
    
    func deletePin(id: String) async throws {
        try await firestoreService.removeDocument(
            path: pinsPath,
            documentId: id
        )
    }
}
