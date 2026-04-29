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
    private var friendRequestListenerTask: Task<Void, Never>?
    private var threadListenerTask: Task<Void, Never>?

    init(friendRepository: FriendRepository, messageRepository: MessageRepository) {
        self.friendRepository = friendRepository
        self.messageRepository = messageRepository
    }

    deinit {
        friendRequestListenerTask?.cancel()
        threadListenerTask?.cancel()
    }

    var pendingRequestCount: Int { pendingRequests.count }
    var messageCount: Int { unreadThreads.count }
    var totalCount: Int { pendingRequestCount + messageCount }
    var hasNotifications: Bool { totalCount > 0 }

    func loadNotifications() async {
        errorMessage = ""

        // Start real-time listener for friend requests (only once)
        if friendRequestListenerTask == nil {
            friendRequestListenerTask = Task {
                do {
                    let stream = friendRepository.incomingRequestsStream()
                    for try await requests in stream {
                        pendingRequests = requests

                        var senders: [String: UserInfo] = [:]
                        for request in requests {
                            if let user = await friendRepository.fetchUser(uid: request.senderUid) {
                                senders[request.senderUid] = user
                            }
                        }
                        requestSenders = senders
                    }
                } catch {
                    errorMessage = "Failed to load notifications."
                    print("HomeViewModel friend request stream error: \(error)")
                }
            }
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
