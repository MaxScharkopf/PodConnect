//
//  MapRepository.swift
//  PodConnect
//
//  Created by Jacob Russell on 4/15/26.
//

import FirebaseFirestore
import Foundation
import CoreLocation

final class MapRepository {
    
    private let firestoreService: FirestoreService
    private var authService: AuthService
    private let pinsPath = "pins"
    
    init(firestoreService: FirestoreService, authService: AuthService) {
        self.firestoreService = firestoreService
        self.authService = authService
    }
    
    func fetchCurrentUserPins() async throws -> [MapPin] {
        guard let userId = authService.userInfo?.id else {
            return []
        }

        return try await firestoreService.fetchCollection(path: pinsPath) { collection in
            collection
                .whereField("pinType", isEqualTo: "user")
                .whereField("ownerUserId", isEqualTo: userId)
        }
    }
    
    func createUserPin(name: String, subtitle: String?, coordinate: CLLocationCoordinate2D) async throws {
        guard let userId = authService.userInfo?.id else {
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
            createdAt: Timestamp(date: Date())
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
