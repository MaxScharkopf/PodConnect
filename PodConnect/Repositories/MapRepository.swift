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
    
    private struct PinUpdate: Encodable {
        let name: String
        let subtitle: String?
        let sharedWith: [String]
    }
    
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
    
    func createUserPin(name: String, subtitle: String?, coordinate: CLLocationCoordinate2D, sharedWith: [String]) async throws -> MapPin {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "MapRepository",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "User not authenticated."]
            )
        }
        
        let docRef = Firestore.firestore().collection(pinsPath).document()
            
        let pin = MapPin(
            id: docRef.documentID,
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
        
        try docRef.setData(from: pin)
        return pin
    }
    
    func updatePin(id: String, name: String, subtitle: String?, sharedWith: [String]) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "MapRepository",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "User not authenticated."]
            )
        }
        
        let update = PinUpdate(name: name, subtitle: subtitle, sharedWith: sharedWith)
        
        try await firestoreService.updateDocument(
            path: pinsPath,
            documentId: id,
            data: update
            )
    }
    
    func deletePin(id: String) async throws {
        try await firestoreService.removeDocument(
            path: pinsPath,
            documentId: id
        )
    }
}
