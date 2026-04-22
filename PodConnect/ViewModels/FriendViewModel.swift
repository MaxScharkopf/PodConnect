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

    init(friendRepository: FriendRepository) {
        self.friendRepository = friendRepository
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
    
    // Fetch friends
    func fetchFriends() async {
        do {
            friends = try await friendRepository.fetchFriends()
        } catch {
            print("Error fetching friends: \(error)")
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
    
    // Fetch incoming friend requests
    func fetchIncomingRequests() async {
        do {
            incomingRequests = try await friendRepository.fetchIncomingRequests()
        } catch {
            print("Error fetching incoming requests: \(error)")
        }
    }

    // Accept
    func acceptRequest(_ request: FriendRequest) async {
        do {
            try await friendRepository.acceptRequest(request)
            incomingRequests.removeAll { $0.id == request.id }
            await fetchFriends()
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
