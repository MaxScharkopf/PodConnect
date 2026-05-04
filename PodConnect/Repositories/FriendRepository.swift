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
        guard let currentUID = Auth.auth().currentUser?.uid else { return [] }
        
        let users: [UserInfo] = try await firestoreService.fetchCollection(
            path: "users",
            configure: { query in
                query.order(by: "username_lowercase")
                    .start(at: [cleaned])
                    .end(at: [cleaned + "\u{f8ff}"])
            }
        )
        
        let currentUser: UserInfo? = try? await firestoreService.fetchDocument(path: "users", documentId: currentUID)
        let blockedUsers = currentUser?.blockedUsers ?? []
        let blockedBy = currentUser?.blockedBy ?? []
        
        return users.filter {
            $0.uid != currentUID &&
            !blockedBy.contains($0.uid)
        }
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
        guard let currentUID = Auth.auth().currentUser?.uid else {
            return .none
        }
        
        do {
            // 1. Check if already friends (user1 → user2)
            let friends: [Friend] = try await firestoreService.fetchCollection(
                path: "friends",
                configure: { query in
                    query.whereField("user1UID", isEqualTo: currentUID)
                        .whereField("user2UID", isEqualTo: withUID)
                }
            )
            if !friends.isEmpty { return .friends }
            
            // 2. Check reverse (user2 → user1)
            let friendsReverse: [Friend] = try await firestoreService.fetchCollection(
                path: "friends",
                configure: { query in
                    query.whereField("user2UID", isEqualTo: currentUID)
                        .whereField("user1UID", isEqualTo: withUID)
                }
            )
            if !friendsReverse.isEmpty { return .friends }
            
            // 3. Check if YOU sent a request
            let sentRequests: [FriendRequest] = try await firestoreService.fetchCollection(
                path: "friendRequests",
                configure: { query in
                    query.whereField("senderUid", isEqualTo: currentUID)
                        .whereField("receiverUid", isEqualTo: withUID)
                        .whereField("status", isEqualTo: "pending")
                }
            )
            if !sentRequests.isEmpty { return .requestSent }
            
            // 4. Check if THEY sent YOU a request
            let receivedRequests: [FriendRequest] = try await firestoreService.fetchCollection(
                path: "friendRequests",
                configure: { query in
                    query.whereField("senderUid", isEqualTo: withUID)
                        .whereField("receiverUid", isEqualTo: currentUID)
                        .whereField("status", isEqualTo: "pending")
                }
            )
            if !receivedRequests.isEmpty { return .requestReceived }
            
            // 5. Check if blocked
            if let currentUser: UserInfo = try? await firestoreService.fetchDocument(path: "users", documentId: currentUID) {
                if currentUser.blockedUsers?.contains(withUID) == true {
                    return .blocked
                }
            }
            
            // 6. Nothing exists
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
    
    func fetchOtherUsers(limit: Int = 10) async throws -> [UserInfo] {
        guard let currentUID = Auth.auth().currentUser?.uid else { return [] }
        
        // Fetch a sample of users from the collection
        let users: [UserInfo] = try await firestoreService.fetchCollection(path: "users") { query in
            query.limit(to: limit + 1)
        }
        
        // Filter out the current user and limit the results
        return Array(users.filter { $0.uid != currentUID }.prefix(limit))
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
    
    func incomingRequestsStream() -> AsyncThrowingStream<[FriendRequest], Error> {
        AsyncThrowingStream { continuation in
            guard let currentUID = Auth.auth().currentUser?.uid else {
                continuation.yield([])
                continuation.finish()
                return
            }
            
            let listener = Firestore.firestore()
                .collection("friendRequests")
                .whereField("receiverUid", isEqualTo: currentUID)
                .whereField("status", isEqualTo: "pending")
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        continuation.finish(throwing: error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        continuation.yield([])
                        return
                    }
                    
                    let requests: [FriendRequest] = documents.compactMap { document in
                        let data = document.data()
                        
                        guard
                            let senderUid = data["senderUid"] as? String,
                            let receiverUid = data["receiverUid"] as? String,
                            let status = data["status"] as? String,
                            let timestamp = data["timestamp"] as? Timestamp
                        else {
                            return nil
                        }
                        
                        return FriendRequest(
                            id: document.documentID,
                            senderUid: senderUid,
                            receiverUid: receiverUid,
                            status: status,
                            timestamp: timestamp
                        )
                    }
                    
                    continuation.yield(requests)
                }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
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
    
    func friendsStream() -> AsyncThrowingStream<[UserInfo], Error> {
        AsyncThrowingStream { continuation in
            guard let currentUID = Auth.auth().currentUser?.uid else {
                continuation.yield([])
                continuation.finish()
                return
            }
            
            let db = Firestore.firestore()
            
            let user1Query = db.collection("friends")
                .whereField("user1UID", isEqualTo: currentUID)
            
            let user2Query = db.collection("friends")
                .whereField("user2UID", isEqualTo: currentUID)
            
            var user1Docs: [QueryDocumentSnapshot] = []
            var user2Docs: [QueryDocumentSnapshot] = []
            
            func emitFriends() {
                Task {
                    let allDocs = user1Docs + user2Docs
                    
                    let friendUIDs = allDocs.compactMap { document -> String? in
                        let data = document.data()
                        let user1 = data["user1UID"] as? String ?? ""
                        let user2 = data["user2UID"] as? String ?? ""
                        
                        if user1 == currentUID {
                            return user2
                        } else if user2 == currentUID {
                            return user1
                        } else {
                            return nil
                        }
                    }
                    
                    var results: [UserInfo] = []
                    for uid in friendUIDs {
                        if let user: UserInfo = try? await self.firestoreService.fetchDocument(path: "users", documentId: uid) {
                            results.append(user)
                        }
                    }
                    
                    await MainActor.run {
                        continuation.yield(results)
                    }
                }
            }
            
            let listener1 = user1Query.addSnapshotListener { snapshot, error in
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                
                user1Docs = snapshot?.documents ?? []
                emitFriends()
            }
            
            let listener2 = user2Query.addSnapshotListener { snapshot, error in
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                
                user2Docs = snapshot?.documents ?? []
                emitFriends()
            }
            
            continuation.onTermination = { _ in
                listener1.remove()
                listener2.remove()
            }
        }
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
    
    func blockUser(uid: String) async throws {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        
        // Unfriend first if friends
        try await unfriend(uid: uid)
        
        let db = Firestore.firestore()
        
        // Add to current user's blockedUsers
        try await db.collection("users").document(currentUID).updateData([
            "blockedUsers": FieldValue.arrayUnion([uid])
        ])
        
        // Add current user to their blockedBy
        try await db.collection("users").document(uid).updateData([
            "blockedBy": FieldValue.arrayUnion([currentUID])
        ])
    }
    
    func unblockUser(uid: String) async throws {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Remove from current user's blockedUsers
        try await db.collection("users").document(currentUID).updateData([
            "blockedUsers": FieldValue.arrayRemove([uid])
        ])
        
        // Remove current user from their blockedBy
        try await db.collection("users").document(uid).updateData([
            "blockedBy": FieldValue.arrayRemove([currentUID])
        ])
    }
    
    func cancelFriendRequest(toUID: String) async throws {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        
        let existingRequests: [FriendRequest] = try await firestoreService.fetchCollection(
            path: "friendRequests",
            configure: { query in
                query.whereField("senderUid", isEqualTo: currentUID)
                    .whereField("receiverUid", isEqualTo: toUID)
                    .whereField("status", isEqualTo: "pending")
            }
        )
        
        guard let requestId = existingRequests.first?.id else { return }
        
        try await firestoreService.removeDocument(
            path: "friendRequests",
            documentId: requestId
        )
    }
    
    func relationshipStatusStream(withUID otherUID: String) -> AsyncThrowingStream<RelationshipStatus, Error> {
        AsyncThrowingStream { continuation in
            guard let currentUID = Auth.auth().currentUser?.uid else {
                continuation.yield(.none)
                continuation.finish()
                return
            }
            
            let db = Firestore.firestore()
            
            let friendQuery1 = db.collection("friends")
                .whereField("user1UID", isEqualTo: currentUID)
                .whereField("user2UID", isEqualTo: otherUID)
            
            let friendQuery2 = db.collection("friends")
                .whereField("user2UID", isEqualTo: currentUID)
                .whereField("user1UID", isEqualTo: otherUID)
            
            let sentRequestQuery = db.collection("friendRequests")
                .whereField("senderUid", isEqualTo: currentUID)
                .whereField("receiverUid", isEqualTo: otherUID)
                .whereField("status", isEqualTo: "pending")
            
            let receivedRequestQuery = db.collection("friendRequests")
                .whereField("senderUid", isEqualTo: otherUID)
                .whereField("receiverUid", isEqualTo: currentUID)
                .whereField("status", isEqualTo: "pending")
            
            var hasFriend1 = false
            var hasFriend2 = false
            var hasSentRequest = false
            var hasReceivedRequest = false
            
            func emitStatus() {
                let status: RelationshipStatus
                if hasFriend1 || hasFriend2 {
                    status = .friends
                } else if hasSentRequest {
                    status = .requestSent
                } else if hasReceivedRequest {
                    status = .requestReceived
                } else {
                    status = .none
                }
                continuation.yield(status)
            }
            
            let listener1 = friendQuery1.addSnapshotListener { snapshot, error in
                if let error = error { continuation.finish(throwing: error); return }
                hasFriend1 = !(snapshot?.documents.isEmpty ?? true)
                emitStatus()
            }
            
            let listener2 = friendQuery2.addSnapshotListener { snapshot, error in
                if let error = error { continuation.finish(throwing: error); return }
                hasFriend2 = !(snapshot?.documents.isEmpty ?? true)
                emitStatus()
            }
            
            let listener3 = sentRequestQuery.addSnapshotListener { snapshot, error in
                if let error = error { continuation.finish(throwing: error); return }
                hasSentRequest = !(snapshot?.documents.isEmpty ?? true)
                emitStatus()
            }
            
            let listener4 = receivedRequestQuery.addSnapshotListener { snapshot, error in
                if let error = error { continuation.finish(throwing: error); return }
                hasReceivedRequest = !(snapshot?.documents.isEmpty ?? true)
                emitStatus()
            }
            
            continuation.onTermination = { _ in
                listener1.remove()
                listener2.remove()
                listener3.remove()
                listener4.remove()
            }
        }
    }
}
