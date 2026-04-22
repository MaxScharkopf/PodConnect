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

    func searchUsers(by usernameQuery: String) async throws -> [UserInfo] {
        let cleaned = usernameQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleaned.isEmpty else { return [] }

        return try await firestoreService.fetchCollection(
            path: "users",
            configure: { query in
                query.order(by: "username_lowercase")
                    .start(at: [cleaned])
                    .end(at: [cleaned + "\u{f8ff}"])
            }
        )
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
                query.whereField("senderUid", isEqualTo: currentUID)
                    .whereField("receiverUid", isEqualTo: toUID)
                    .whereField("status", isEqualTo: "pending")
            }
        )
        
        if !existingRequests.isEmpty {
            throw FriendRequestError.requestAlreadySent
        }

        // Send request
        let request = FriendRequest(
            id: nil,
            senderUid: currentUID,
            receiverUid: toUID,
            status: "pending",
            timestamp: Timestamp(date: Date())
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
                    query.whereField("user2UID", isEqualTo: currentUID)
                        .whereField("user1UID", isEqualTo: withUID)
                }
            )
            if !friendsReverse.isEmpty { return .friends }
            
            // Check if request already sent
            let requests: [FriendRequest] = try await firestoreService.fetchCollection(
                path: "friendRequests",
                configure: { query in
                    query.whereField("senderUid", isEqualTo: currentUID)
                        .whereField("receiverUid", isEqualTo: withUID)
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
    
    func fetchFriends() async throws -> [UserInfo] {
        guard let currentUID = Auth.auth().currentUser?.uid else { return [] }

        // Where current user is user1
        let asUser1: [Friend] = try await firestoreService.fetchCollection(
            path: "friends",
            configure: { query in
                query.whereField("user1UID", isEqualTo: currentUID)
            }
        )

        // Where current user is user2
        let asUser2: [Friend] = try await firestoreService.fetchCollection(
            path: "friends",
            configure: { query in
                query.whereField("user2UID", isEqualTo: currentUID)
            }
        )

        // Get other user's UID from each document
        let friendUIDs = asUser1.map { $0.user2UID } + asUser2.map { $0.user1UID }

        // Fetch each friend's UserInfo by their UID
        var results: [UserInfo] = []
        for uid in friendUIDs {
            if let user: UserInfo = try await firestoreService.fetchDocument(path: "users", documentId: uid) {
                results.append(user)
            }
        }
        return results
    }
    
    func fetchUser(uid: String) async -> UserInfo? {
        return try? await firestoreService.fetchDocument(path: "users", documentId: uid)
    }
    
    func fetchIncomingRequests() async throws -> [FriendRequest] {
        guard let currentUID = Auth.auth().currentUser?.uid else { return [] }

        return try await firestoreService.fetchCollection(
            path: "friendRequests",
            configure: { query in
                query.whereField("receiverUid", isEqualTo: currentUID)
                    .whereField("status", isEqualTo: "pending")
            }
        )
    }

    func acceptRequest(_ request: FriendRequest) async throws {
        guard let requestId = request.id else { return }

        // Create the friendship
        let friendship = Friend(
            id: nil,
            user1UID: request.senderUid,
            user2UID: request.receiverUid,
            since: Date()
        )

        try await firestoreService.saveDocument(
            path: "friends",
            data: friendship
        )

        // Delete the request
        try await firestoreService.removeDocument(
            path: "friendRequests",
            documentId: requestId
        )
    }

    func declineRequest(_ request: FriendRequest) async throws {
        guard let requestId = request.id else { return }

        try await firestoreService.removeDocument(
            path: "friendRequests",
            documentId: requestId
        )
    }
    
    func unfriend(uid: String) async throws {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }

        // Check user1UID == currentUID
        let asUser1: [Friend] = try await firestoreService.fetchCollection(
            path: "friends",
            configure: { query in
                query.whereField("user1UID", isEqualTo: currentUID)
                    .whereField("user2UID", isEqualTo: uid)
            }
        )

        // Check user2UID == currentUID
        let asUser2: [Friend] = try await firestoreService.fetchCollection(
            path: "friends",
            configure: { query in
                query.whereField("user2UID", isEqualTo: currentUID)
                    .whereField("user1UID", isEqualTo: uid)
            }
        )

        let friendship = asUser1.first ?? asUser2.first
        guard let documentId = friendship?.id else { return }

        try await firestoreService.removeDocument(
            path: "friends",
            documentId: documentId
        )
    }
}
