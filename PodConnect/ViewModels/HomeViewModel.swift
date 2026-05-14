//
//  HomeViewModel.swift
//  PodConnect
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

enum NotificationFilter: String, CaseIterable {
    case all = "All"
    case friendRequests = "Friend Requests"
    case pinRequests = "Pin Requests"
    case messages = "Messages"
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var pendingRequests: [FriendRequest] = []
    @Published var requestSenders: [String: UserInfo] = [:]
    @Published var unreadThreads: [MessageThread] = []
    @Published var pendingMessageRequests: [MessageThread] = []
    @Published var pendingPinShareRequests: [PinShareRequest] = []
    @Published var participantUsernames: [String: String] = [:]
    @Published var activeFilter: NotificationFilter = .all
    @Published var errorMessage: String = ""

    private let friendRepository: FriendRepository
    private let messageRepository: MessageRepository
    private let pinShareRepository: PinShareRepository

    private var friendRequestListenerTask: Task<Void, Never>?
    private var threadListenerTask: Task<Void, Never>?
    private var messageRequestListenerTask: Task<Void, Never>?
    private var pinShareListener: ListenerRegistration?

    init(
        friendRepository: FriendRepository,
        messageRepository: MessageRepository,
        pinShareRepository: PinShareRepository
    ) {
        self.friendRepository = friendRepository
        self.messageRepository = messageRepository
        self.pinShareRepository = pinShareRepository
    }

    deinit {
        friendRequestListenerTask?.cancel()
        threadListenerTask?.cancel()
        messageRequestListenerTask?.cancel()
        pinShareListener?.remove()
    }

    var pendingRequestCount: Int { pendingRequests.count }
    var messageCount: Int { unreadThreads.count + pendingMessageRequests.count }
    var pinShareCount: Int { pendingPinShareRequests.count }
    var totalCount: Int { pendingRequestCount + messageCount + pinShareCount }
    var hasNotifications: Bool { totalCount > 0 }

    func loadNotifications() async {
        errorMessage = ""

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

        if threadListenerTask == nil {
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
                        
                        // Fetch missing usernames
                        for thread in unreadThreads {
                            for id in (thread.participants + thread.pendingParticipants) {
                                if id != userId && participantUsernames[id] == nil {
                                    if let user = await friendRepository.fetchUser(uid: id) {
                                        participantUsernames[id] = user.username
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    print("HomeViewModel thread stream error: \(error)")
                }
            }
        }

        if messageRequestListenerTask == nil {
            messageRequestListenerTask = Task {
                let userId = Auth.auth().currentUser?.uid ?? ""
                let stream = messageRepository.messageRequestsStream()

                do {
                    for try await requests in stream {
                        pendingMessageRequests = requests
                        
                        // Fetch missing usernames
                        for thread in requests {
                            for id in (thread.participants + thread.pendingParticipants) {
                                if id != userId && participantUsernames[id] == nil {
                                    if let user = await friendRepository.fetchUser(uid: id) {
                                        participantUsernames[id] = user.username
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    print("HomeViewModel message request stream error: \(error)")
                }
            }
        }

        startListening()
    }

    func startListening() {
        guard pinShareListener == nil else { return }
        guard let currentUid = Auth.auth().currentUser?.uid else { return }

        pinShareListener = pinShareRepository.listenToIncomingRequests(for: currentUid) { [weak self] requests in
            Task { @MainActor in
                self?.pendingPinShareRequests = requests
            }
        }
    }

    func stopListening() {
        pinShareListener?.remove()
        pinShareListener = nil
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

    func markAsRead(threadId: String) async {
        try? await messageRepository.markThreadAsRead(threadId: threadId)
    }

    func getParticipantSummary(for thread: MessageThread) -> String {
        let currentUserId = Auth.auth().currentUser?.uid
        let allIds = thread.participants + thread.pendingParticipants
        let otherIds = allIds.filter { $0 != currentUserId }
        
        let names = otherIds.compactMap { participantUsernames[$0] }
        
        if names.isEmpty {
            return "New Chat"
        }
        
        return names.joined(separator: ", ")
    }
}
