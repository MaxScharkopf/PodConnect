//
//  FriendViewModel.swift
//  PodConnect
//
//  Created by Desiree Astabie on 4/6/26.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class FriendViewModel: ObservableObject {

    let friendRepository: FriendRepository

    @Published var searchResults: UserInfo? = nil
    @Published var searchErrorMessage: String = ""
    @Published var sendErrorMessage: String = ""
    @Published var sendSuccessMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var friends: [UserInfo] = []
    @Published var relationshipStatus: RelationshipStatus = .none
    @Published var incomingRequests: [FriendRequest] = []
    @Published var requestErrorMessage: String = ""

    private var incomingRequestsListenerTask: Task<Void, Never>?
    private var friendsListenerTask: Task<Void, Never>?

    init(friendRepository: FriendRepository) {
        self.friendRepository = friendRepository
    }

    deinit {
        incomingRequestsListenerTask?.cancel()
        friendsListenerTask?.cancel()
    }

    // Search for a user by username
    func searchUser(username: String) async {
        searchResults = nil
        searchErrorMessage = ""

        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchErrorMessage = "Please enter a username."
            return
        }

        isLoading = true

        do {
            let users = try await friendRepository.searchUsers(by: username)
            if let user = users.first {
                searchResults = user
            } else {
                searchErrorMessage = "Username not found."
            }
        } catch {
            searchErrorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
    // Check relationship status with a user
    func checkRelationshipStatus(withUID: String) async {
        relationshipStatus = await friendRepository.getRelationshipStatus(withUID: withUID)
    }

    // Send a friend request
    func sendFriendRequest(toUID: String) async {
        sendErrorMessage = ""
        sendSuccessMessage = ""
        isLoading = true

        do {
            try await friendRepository.sendFriendRequest(toUID: toUID)
            sendSuccessMessage = "Sent."
        } catch {
            sendErrorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
    func cancelFriendRequest(toUID: String) async {
        do {
            try await friendRepository.cancelFriendRequest(toUID: toUID)
        } catch {
            sendErrorMessage = error.localizedDescription
        }
    }
    
    // Live friends
    func fetchFriends() async {
        guard friendsListenerTask == nil else { return }

        friendsListenerTask = Task {
            do {
                let stream = friendRepository.friendsStream()
                for try await friendsList in stream {
                    friends = friendsList
                }
            } catch {
                print("Error listening for friends: \(error)")
            }
        }
    }
    
    // Unfriend
    func unfriend(uid: String) async {
        do {
            try await friendRepository.unfriend(uid: uid)
            friends.removeAll { $0.uid == uid }
        } catch {
            print("Error unfriending: \(error)")
        }
    }
    
    // Block a user
    func blockUser(uid: String) async {
        do {
            try await friendRepository.blockUser(uid: uid)
            friends.removeAll { $0.uid == uid }
        } catch {
            print("Error blocking user: \(error)")
        }
    }

    // Unblock a user
    func unblockUser(uid: String) async {
        do {
            try await friendRepository.unblockUser(uid: uid)
        } catch {
            print("Error unblocking user: \(error)")
        }
    }
    
    // Live incoming friend requests
    func fetchIncomingRequests() async {
        guard incomingRequestsListenerTask == nil else { return }

        incomingRequestsListenerTask = Task {
            do {
                let stream = friendRepository.incomingRequestsStream()
                for try await requests in stream {
                    incomingRequests = requests
                }
            } catch {
                print("Error listening for incoming requests: \(error)")
            }
        }
    }

    // Accept
    func acceptRequest(_ request: FriendRequest) async {
        do {
            try await friendRepository.acceptRequest(request)
            incomingRequests.removeAll { $0.id == request.id }
        } catch {
            requestErrorMessage = error.localizedDescription
        }
    }

    // Decline
    func declineRequest(_ request: FriendRequest) async {
        do {
            try await friendRepository.declineRequest(request)
            incomingRequests.removeAll { $0.id == request.id }
        } catch {
            requestErrorMessage = error.localizedDescription
        }
    }
    
}
