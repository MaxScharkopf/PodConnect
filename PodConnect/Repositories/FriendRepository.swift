//
//  FriendRepository.swift
//  PodConnect
//
//  Created by Desiree Astabie on 4/6/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FriendRepository {
    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    func searchUser(username: String) async throws -> UserInfo? {
        let users: [UserInfo] = try await firestoreService.fetchCollection(
            path: "users",
            configure: { query in
                query.whereField("username_lowercase", isEqualTo: username.lowercased())
                    .limit(to: 1)
            }
        )
        return users.first
    }

    func sendFriendRequest(toUID: String) async throws {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }

        // Can't send request to self
        if currentUID == toUID {
            throw FriendRequestError.cannotAddSelf
        }
        
        // If already friends
        let existingFriends: [Friend] = try await firestoreService.fetchCollection(
            path: "friends",
            configure: { query in
                query.whereField("user1UID", isEqualTo: currentUID)
                    .whereField("user2UID", isEqualTo: toUID)
            }
        )
        if !existingFriends.isEmpty {
            throw FriendRequestError.alreadyFriends
        }

        // Block duplicate requests
        let existingRequests: [FriendRequest] = try await firestoreService.fetchCollection(
            path: "friendRequests",
            configure: { query in
                query.whereField("fromUID", isEqualTo: currentUID)
                    .whereField("toUID", isEqualTo: toUID)
                    .whereField("status", isEqualTo: "pending")
            }
        )
        
        if !existingRequests.isEmpty {
            throw FriendRequestError.requestAlreadySent
        }

        // Send request
        let request = FriendRequest(
            fromUID: currentUID,
            toUID: toUID,
            status: "pending",
            timestamp: Date()
        )

        try await firestoreService.saveDocument(
            path: "friendRequests",
            data: request
        )
    }
    
    func getRelationshipStatus(withUID: String) async -> RelationshipStatus {
        guard let currentUID = Auth.auth().currentUser?.uid else { return .none }

        do {
            // Check if already friends
            let friends: [Friend] = try await firestoreService.fetchCollection(
                path: "friends",
                configure: { query in
                    query.whereField("user1UID", isEqualTo: currentUID)
                        .whereField("user2UID", isEqualTo: withUID)
                }
            )
            if !friends.isEmpty { return .friends }

            // Check reverse order too
            let friendsReverse: [Friend] = try await firestoreService.fetchCollection(
                path: "friends",
                configure: { query in
                    query.whereField("user1UID", isEqualTo: withUID)
                        .whereField("user2UID", isEqualTo: currentUID)
                }
            )
            if !friendsReverse.isEmpty { return .friends }

            // Check if request already sent
            let requests: [FriendRequest] = try await firestoreService.fetchCollection(
                path: "friendRequests",
                configure: { query in
                    query.whereField("fromUID", isEqualTo: currentUID)
                        .whereField("toUID", isEqualTo: withUID)
                        .whereField("status", isEqualTo: "pending")
                }
            )
            if !requests.isEmpty { return .requestSent }

            return .none

        } catch {
            print("Error checking relationship status: \(error)")
            return .none
        }
    }
}



struct FriendRequest: Codable {
    var id: String?
    let fromUID: String
    let toUID: String
    let status: String
    let timestamp: Date
}

struct Friend: Codable {
    var id: String?
    let user1UID: String
    let user2UID: String
    let since: Date
}

enum FriendRequestError: LocalizedError {
    case cannotAddSelf
    case alreadyFriends
    case requestAlreadySent

    var errorDescription: String? {
        switch self {
        case .cannotAddSelf:
            return "You can't send a friend request to yourself."
        case .alreadyFriends:
            return "You are already friends with this user."
        case .requestAlreadySent:
            return "A friend request has already been sent to this user."
        }
    }
}

enum RelationshipStatus {
    case none
    case requestSent
    case friends
}
