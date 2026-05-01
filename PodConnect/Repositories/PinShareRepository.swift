//
//  PinShareRepository.swift
//  PodConnect
//
//  Created by Jacob Russell on 4/30/26.
//

import FirebaseCore
import Foundation
import FirebaseFirestore

final class PinShareRepository {
    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    func sendShareRequest(
        pinId: String,
        pinName: String,
        senderUid: String,
        receiverUid: String
    ) async throws {
        let existing: [PinShareRequest] = try await firestoreService.fetchCollection(
            path: "pinShareRequests",
            configure: { query in
                query
                    .whereField("pinId", isEqualTo: pinId)
                    .whereField("receiverUid", isEqualTo: receiverUid)
                    .whereField("status", isEqualTo: "pending")
            }
        )

        guard existing.isEmpty else { return }
        
        let request = PinShareRequest(
            id: nil,
            pinId: pinId,
            pinName: pinName,
            senderUid: senderUid,
            receiverUid: receiverUid,
            status: "pending",
            timestamp: Timestamp(date: Date())
        )

        try await firestoreService.saveDocument(
            path: "pinShareRequests",
            data: request
        )
    }
    
    func fetchIncomingRequests(for receiverUid: String) async throws -> [PinShareRequest] {
        try await firestoreService.fetchCollection(
            path: "pinShareRequests",
            configure: { query in
                query
                    .whereField("receiverUid", isEqualTo: receiverUid)
                    .whereField("status", isEqualTo: "pending")
            }
        )
    }
    
    func fetchPendingReceiverUIDs(for pinId: String) async throws -> [String] {
        let requests: [PinShareRequest] = try await firestoreService.fetchCollection(
            path: "pinShareRequests",
            configure: { query in
                query
                    .whereField("pinId", isEqualTo: pinId)
                    .whereField("status", isEqualTo: "pending")
            }
        )

        return requests.map { $0.receiverUid }
    }
    
    func declineShareRequest(_ request: PinShareRequest) async throws {
        guard let requestId = request.id else { return }

        let update = RequestStatusUpdate(status: "declined")

        try await firestoreService.updateDocument(
            path: "pinShareRequests",
            documentId: requestId,
            data: update
        )
    }

    func acceptShareRequest(_ request: PinShareRequest) async throws {
        guard let requestId = request.id else { return }

        guard let pin: MapPin = try await firestoreService.fetchDocument(
            path: "pins",
            documentId: request.pinId
        ) else {
            return
        }

        let currentSharedWith = pin.sharedWith ?? []
        let updatedSharedWith = Array(Set(currentSharedWith + [request.receiverUid]))

        let pinUpdate = PinSharedWithUpdate(sharedWith: updatedSharedWith)

        try await firestoreService.updateDocument(
            path: "pins",
            documentId: request.pinId,
            data: pinUpdate
        )

        let requestUpdate = RequestStatusUpdate(status: "accepted")

        try await firestoreService.updateDocument(
            path: "pinShareRequests",
            documentId: requestId,
            data: requestUpdate
        )
    }
}
