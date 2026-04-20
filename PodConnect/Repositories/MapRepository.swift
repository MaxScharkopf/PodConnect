//
//  MapRepository.swift
//  PodConnect
//
//  Created by Jacob Russell on 4/15/26.
//

import FirebaseFirestore
import Foundation

final class MapRepository {
    
    private let firestoreService: FirestoreService
    private let pinsPath = "pins"
    
    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }
    
    func fetchPins(
        category: String? = nil,
        pinType: String? = nil,
        ownerUserId: String? = nil
    ) async throws -> [MapPin] {
        try await firestoreService.fetchCollection(path: pinsPath) { collection in
            var query: Query = collection

            if let category {
                query = query.whereField("category", isEqualTo: category)
            }

            if let pinType {
                query = query.whereField("pinType", isEqualTo: pinType)
            }

            if let ownerUserId {
                query = query.whereField("ownerUserId", isEqualTo: ownerUserId)
            }

            return query
        }
    }
    
    func listenToPins() -> AsyncThrowingStream<[MapPin], Error> {
        firestoreService.createCollectionListener(path: pinsPath)
    }
    
    func savePin(_ pin: MapPin) async throws {
        try await firestoreService.saveDocument(path: pinsPath, data: pin)
    }
    
    func updatePin(id: String, pin: MapPin) async throws {
        try await firestoreService.updateDocument(
            path: pinsPath,
            documentId: id,
            data: pin
        )
    }
    
    func deletePin(id: String) async throws {
        try await firestoreService.removeDocument(
            path: pinsPath,
            documentId: id
        )
    }
}
