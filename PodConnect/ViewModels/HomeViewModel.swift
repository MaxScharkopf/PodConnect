//
//  HomeViewModel.swift
//  PodConnect
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var pendingRequestCount: Int = 0
    @Published var pendingPinShareCount: Int = 0
    @Published var errorMessage: String = ""

    private let friendRepository: FriendRepository
    private let pinShareRepository: PinShareRepository

    private var pinShareListener: ListenerRegistration?
    
    init(friendRepository: FriendRepository, pinShareRepository: PinShareRepository) {
        self.friendRepository = friendRepository
        self.pinShareRepository = pinShareRepository

    }

    var hasNotifications: Bool {
        pendingRequestCount > 0 || pendingPinShareCount > 0
    }

    func loadNotifications() async {
        errorMessage = ""

        do {
            let requests = try await friendRepository.fetchIncomingRequests()
            pendingRequestCount = requests.count
            
            guard let currentUid = Auth.auth().currentUser?.uid else {
                pendingPinShareCount = 0
                return
            }
            
            let pinRequests = try await pinShareRepository.fetchIncomingRequests(for: currentUid)
            pendingPinShareCount = pinRequests.count
            
        } catch {
            errorMessage = "Failed to load notifications."
            print("HomeViewModel loadNotifications error: \(error)")
        }
    }
    
    func startListening() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }

        pinShareListener?.remove()

        pinShareListener = pinShareRepository.listenToIncomingRequests(for: currentUid) { [weak self] requests in
            Task { @MainActor in
                self?.pendingPinShareCount = requests.count
            }
        }
    }

    func stopListening() {
        pinShareListener?.remove()
        pinShareListener = nil
    }

    deinit {
        pinShareListener?.remove()
    }
}
