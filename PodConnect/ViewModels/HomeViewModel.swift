//
//  HomeViewModel.swift
//  PodConnect
//

import Foundation
import Combine
import FirebaseAuth

enum NotificationFilter: String, CaseIterable {
    case all = "All"
    case friendRequests = "Friend Requests"
    case messages = "Messages"
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var pendingRequests: [FriendRequest] = []
    @Published var requestSenders: [String: UserInfo] = [:]
    @Published var unreadThreads: [MessageThread] = []
    @Published var activeFilter: NotificationFilter = .all
    @Published var errorMessage: String = ""

    private let friendRepository: FriendRepository
    private let messageRepository: MessageRepository
    private var threadListenerTask: Task<Void, Never>?

    init(friendRepository: FriendRepository, messageRepository: MessageRepository) {
        self.friendRepository = friendRepository
        self.messageRepository = messageRepository
    }

    deinit {
        threadListenerTask?.cancel()
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
            pendingRequests = requests
            for request in requests {
                if let user = await friendRepository.fetchUser(uid: request.senderUid) {
                    requestSenders[request.senderUid] = user
                }
            }
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
}
