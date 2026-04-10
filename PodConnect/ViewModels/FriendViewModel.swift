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

    private let friendRepository: FriendRepository

    @Published var searchResults: UserInfo? = nil
    @Published var searchErrorMessage: String = ""
    @Published var sendErrorMessage: String = ""
    @Published var sendSuccessMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var relationshipStatus: RelationshipStatus = .none

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
}
