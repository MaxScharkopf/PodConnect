//
//  PinShare.swift
//  PodConnect
//
//  Created by Jacob Russell on 4/30/26.
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
class PinShareViewModel: ObservableObject {
    @Published var incomingRequests: [PinShareRequest] = []
    @Published var errorMessage: String?

    private let pinShareRepository: PinShareRepository

    init(pinShareRepository: PinShareRepository) {
        self.pinShareRepository = pinShareRepository
    }

    func loadIncomingRequests() async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }

        do {
            incomingRequests = try await pinShareRepository.fetchIncomingRequests(for: currentUid)
        } catch {
            errorMessage = "Failed to load share requests: \(error.localizedDescription)"
        }
    }
    
    func fetchPendingReceiverUIDs(for pinId: String) async throws -> [String] {
        try await pinShareRepository.fetchPendingReceiverUIDs(for: pinId)
    }
    
    func sendRequest(pinId: String, pinName: String, receiverUid: String) async {
        guard let currentUser = Auth.auth().currentUser else { return }
        let currentUid = currentUser.uid
        let senderName = currentUser.displayName ?? "Someone"

        do {
            try await pinShareRepository.sendShareRequest(
                pinId: pinId,
                pinName: pinName,
                senderUid: currentUid,
                senderName: senderName,
                receiverUid: receiverUid
            )
        } catch {
            errorMessage = "Failed to send share request: \(error.localizedDescription)"
        }
    }

    func acceptRequest(_ request: PinShareRequest) async {
        do {
            try await pinShareRepository.acceptShareRequest(request)
            await loadIncomingRequests()
        } catch {
            errorMessage = "Failed to accept request: \(error.localizedDescription)"
        }
    }

    func declineRequest(_ request: PinShareRequest) async {
        do {
            try await pinShareRepository.declineShareRequest(request)
            await loadIncomingRequests()
        } catch {
            errorMessage = "Failed to decline request: \(error.localizedDescription)"
        }
    }
}
