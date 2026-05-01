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

    var pendingRequestCount: Int { pendingRequests.count }
    var messageCount: Int { unreadThreads.count }
    var totalCount: Int { pendingRequestCount + messageCount }
    var hasNotifications: Bool { totalCount > 0 }

    func loadNotifications() async {
        errorMessage = ""

        // One-time fetch for friend requests
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

        // Start real-time listener for message threads (only once)
        guard threadListenerTask == nil else { return }
        threadListenerTask = Task {
            let userId = Auth.auth().currentUser?.uid ?? ""
            let stream = messageRepository.messageThreadsStream()
            do {
                for try await threads in stream {
                    unreadThreads = threads.filter { thread in
                        guard let lastMessageAt = thread.lastMessageAt else { return false }
                        guard let lastReadAt = thread.lastReadAt?[userId] else { return true }
                        return lastMessageAt > lastReadAt
                    }
                }
            } catch {
                print("HomeViewModel thread stream error: \(error)")
            }
        }
    }

    func acceptRequest(_ request: FriendRequest) async {
        do {
            try await friendRepository.acceptRequest(request)
            pendingRequests.removeAll { $0.id == request.id }
        } catch {
            errorMessage = "Failed to accept request."
        }
    }

    func declineRequest(_ request: FriendRequest) async {
        do {
            try await friendRepository.declineRequest(request)
            pendingRequests.removeAll { $0.id == request.id }
        } catch {
            errorMessage = "Failed to decline request."
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
