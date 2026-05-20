//
//  LiveLocationRepository.swift
//  PodConnect
//
//  Created by Jacob Russell on 5/12/26.
//

import Foundation
import FirebaseFirestore

final class LiveLocationRepository {
    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    func startOrUpdateShare(_ share: LiveLocationShare) async throws {
        guard let id = share.id else { return }

        try await firestoreService.saveDocument(
            path: "liveLocationShares",
            documentId: id,
            data: share
        )
    }

    func stopShare(ownerUid: String, receiverUid: String) async throws {
        let documentId = "\(ownerUid)_\(receiverUid)"

        try await Firestore.firestore()
            .collection("liveLocationShares")
            .document(documentId)
            .updateData([
                "isActive": false,
                "updatedAt": Timestamp(date: Date())
            ])
    }

    func listenToIncomingShares(
        for receiverUid: String,
        onChange: @escaping ([LiveLocationShare]) -> Void
    ) -> ListenerRegistration {
        Firestore.firestore()
            .collection("liveLocationShares")
            .whereField("receiverUid", isEqualTo: receiverUid)
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { snapshot, error in
                if let error {
                    print("Live location listener error: \(error.localizedDescription)")
                    onChange([])
                    return
                }

                let shares = snapshot?.documents.compactMap {
                    try? $0.data(as: LiveLocationShare.self)
                } ?? []

                onChange(shares)
            }
    }
}
