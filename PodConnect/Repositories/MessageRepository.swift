//
//  MessageRepository.swift
//  PodConnect
//
//  Created by Noah Hester on 3/27/26.
//

import FirebaseAuth
import FirebaseFirestore
internal import FirebaseFirestoreInternal

// Store core functions for messaging capabilities
final class MessageRepository {
    private var firestoreService: FirestoreService
    private var authService: AuthService
    
    init(firestoreService: FirestoreService, authService: AuthService) {
        self.firestoreService = firestoreService
        self.authService = authService
    }

    func getUserId() -> String? {
        return authService.userInfo?.id
    }

    func fetchUser(uid: String) async -> UserInfo? {
        return try? await firestoreService.fetchDocument(path: "users", documentId: uid)
    }
    
    func fetchMessageThreads() async throws -> [MessageThread] {
        guard let userId = Auth.auth().currentUser?.uid else {
            return []
        }
        
        // Filter for the message threads that have the current user in them as an active participant
        let messageThreads: [MessageThread] = try await firestoreService.fetchCollection(path: "messages") { collection in
            collection.whereField("participants", arrayContains: userId)
        }
        
        // Sort locally to avoid needing a composite index in Firestore
        return messageThreads.sorted(by: { ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast) })
    }

    func fetchMessageRequests() async throws -> [MessageThread] {
        // Check if the user is logged in
        guard let userId = authService.userInfo?.id else {
            return []
        }
        
        // Filter for the message threads that have the current user in them as a pending participant
        let requests: [MessageThread] = try await firestoreService.fetchCollection(path: "messages") { collection in
            collection.whereField("pendingParticipants", arrayContains: userId)
        }
        
        // Sort locally to avoid needing a composite index in Firestore
        return requests.sorted(by: { ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast) })
    }
    
    func fetchMessages(threadId: String) async throws -> [Message] {
        // Check if the user is logged in
        guard authService.isAuthenticated else {
            return []
        }
        
        // Filter for the message threads that have the current user in them
        let messages: [Message] = try await firestoreService.fetchCollection(path: "messages/\(threadId)/messages")
        
        return messages
    }
    
    func messageFetchStream(threadId: String) -> AsyncThrowingStream<[Message], Error> {
        guard authService.isAuthenticated else {
            return AsyncThrowingStream { continuation in
                continuation.yield([])
                continuation.finish()
            }
        }
        
        return firestoreService.createCollectionListener(path: "messages/\(threadId)/messages") { query in
            query.order(by: "timestamp", descending: false)
        }
    }
    
    func sendMessage(threadId: String, messageContent: String) async throws {
        // Check if the user is logged in
        guard let userId = authService.userInfo?.id else {
            return
        }
        
        let now = Date()
        let message = Message(content: messageContent, sender: userId, timestamp: now)

        // Update thread metadata (including sender's lastReadAt) BEFORE saving the message
        // so the real-time listener never sees the sender's own message as unread
        if let thread: MessageThread = try await firestoreService.fetchDocument(path: "messages", documentId: threadId) {
            var updatedThread = thread
            updatedThread.lastMessageAt = now
            var lastReadAt = updatedThread.lastReadAt ?? [:]
            lastReadAt[userId] = now
            updatedThread.lastReadAt = lastReadAt
            try await firestoreService.updateDocument(path: "messages", documentId: threadId, data: updatedThread)
        }

        try await firestoreService.saveDocument(path: "messages/\(threadId)/messages", data: message)
    }

    func markThreadAsRead(threadId: String) async throws {
        guard let userId = authService.userInfo?.id else { return }
        
        if let thread: MessageThread = try await firestoreService.fetchDocument(path: "messages", documentId: threadId) {
            var updatedThread = thread
            var lastReadAt = updatedThread.lastReadAt ?? [:]
            lastReadAt[userId] = Date()
            updatedThread.lastReadAt = lastReadAt
            
            try await firestoreService.updateDocument(path: "messages", documentId: threadId, data: updatedThread)
        }
    }

    func fetchUnreadCount(threadId: String, lastReadAt: Date?) async throws -> Int {
        guard let lastRead = lastReadAt else {
            // If never read, count all messages
            return try await firestoreService.getCount(path: "messages/\(threadId)/messages")
        }
        
        return try await firestoreService.getCount(path: "messages/\(threadId)/messages") { query in
            query.whereField("timestamp", isGreaterThan: lastRead)
        }
    }

    func fetchUnreadMessageThreads() async throws -> [MessageThread] {
        guard let userId = Auth.auth().currentUser?.uid else { return [] }

        let allThreads = try await fetchMessageThreads()
        return allThreads.filter { thread in
            guard let lastMessageAt = thread.lastMessageAt else { return false }
            guard let lastReadAt = thread.lastReadAt?[userId] else { return true }
            return lastMessageAt > lastReadAt
        }
    }

    func messageThreadsStream() -> AsyncThrowingStream<[MessageThread], Error> {
        guard let userId = Auth.auth().currentUser?.uid else {
            return AsyncThrowingStream { continuation in
                continuation.yield([])
                continuation.finish()
            }
        }

        return firestoreService.createCollectionListener(path: "messages") { collection in
            collection.whereField("participants", arrayContains: userId)
        }
    }

    func messageRequestsStream() -> AsyncThrowingStream<[MessageThread], Error> {
        guard let userId = Auth.auth().currentUser?.uid else {
            return AsyncThrowingStream { continuation in
                continuation.yield([])
                continuation.finish()
            }
        }

        return firestoreService.createCollectionListener(path: "messages") { collection in
            collection.whereField("pendingParticipants", arrayContains: userId)
        }
    }
    
    private func findExistingDirectMessageThread(with otherUserId: String) async throws -> MessageThread? {
        guard let currentUserId = authService.userInfo?.id else { return nil }
        
        // Fetch threads where current user is a participant
        let activeThreads: [MessageThread] = try await firestoreService.fetchCollection(path: "messages") { collection in
            collection.whereField("participants", arrayContains: currentUserId)
        }
        
        // Fetch threads where current user is a pending participant
        let pendingThreads: [MessageThread] = try await firestoreService.fetchCollection(path: "messages") { collection in
            collection.whereField("pendingParticipants", arrayContains: currentUserId)
        }
        
        let allThreads = activeThreads + pendingThreads
        
        // Find a 1:1 thread with the target user
        return allThreads.first(where: { thread in
            let allParticipants = thread.participants + thread.pendingParticipants
            return allParticipants.count == 2 && allParticipants.contains(otherUserId) && thread.threadName.isEmpty
        })
    }

    func createMessageThread(threadName: String, participants: [String]) async throws {
        // Check if the user is logged in
        guard let userId = authService.userInfo?.id else {
            return
        }
        
        let otherParticipants = participants.filter { $0 != userId }
        
        // Prevent duplicate 1:1 threads
        if threadName.isEmpty && otherParticipants.count == 1 {
            if let existing = try await findExistingDirectMessageThread(with: otherParticipants[0]) {
                var userInfo: [String: Any] = [NSLocalizedDescriptionKey: "A direct message thread with this user already exists."]
                userInfo["existingThread"] = existing
                throw NSError(domain: "Message", code: 409, userInfo: userInfo)
            }
        }
        
        // The creator is an active participant, everyone else starts as pending
        let activeParticipants = [userId]
        let pendingParticipants = otherParticipants
        
        let thread = MessageThread(
            participants: activeParticipants,
            pendingParticipants: pendingParticipants,
            threadName: threadName,
            lastMessageAt: Date(),
            lastReadAt: nil,
            ownerId: userId
        )
        
        try await firestoreService.saveDocument(path: "messages", data: thread)
    }

    func joinMessageThread(threadId: String) async throws {
        guard let userId = authService.userInfo?.id else { return }
        
        let thread: MessageThread? = try await firestoreService.fetchDocument(path: "messages", documentId: threadId)
        guard var updatedThread = thread else { return }
        
        updatedThread.pendingParticipants.removeAll { $0 == userId }
        if !updatedThread.participants.contains(userId) {
            updatedThread.participants.append(userId)
        }
        
        try await firestoreService.updateDocument(path: "messages", documentId: threadId, data: updatedThread)
    }

    func declineMessageThread(threadId: String) async throws {
        guard let userId = authService.userInfo?.id else { return }
        
        let thread: MessageThread? = try await firestoreService.fetchDocument(path: "messages", documentId: threadId)
        guard var updatedThread = thread else { return }
        
        updatedThread.pendingParticipants.removeAll { $0 == userId }
        
        // If no participants left, delete the thread
        if updatedThread.participants.isEmpty && updatedThread.pendingParticipants.isEmpty {
            try await firestoreService.removeDocument(path: "messages", documentId: threadId)
        } else {
            try await firestoreService.updateDocument(path: "messages", documentId: threadId, data: updatedThread)
        }
    }
    
    func updateMessageThread(threadId: String, threadName: String, participants: [String], pendingParticipants: [String], ownerId: String) async throws {
        let thread = MessageThread(
            participants: participants,
            pendingParticipants: pendingParticipants,
            threadName: threadName,
            lastMessageAt: nil,
            lastReadAt: nil,
            ownerId: ownerId
        )
        
        try await firestoreService.updateDocument(path: "messages", documentId: threadId, data: thread)
    }

    func deleteMessage(threadId: String, messageId: String) async throws {
        try await firestoreService.removeDocument(path: "messages/\(threadId)/messages", documentId: messageId)
    }

    func updateMessage(threadId: String, messageId: String, content: String) async throws {
        let updateData: [String: Any] = [
            "content": content,
            "isEdited": true
        ]
        try await firestoreService.updateFields(path: "messages/\(threadId)/messages", documentId: messageId, fields: updateData)
    }

    func deleteMessageThread(threadId: String) async throws {
        try await firestoreService.removeDocument(path: "messages", documentId: threadId)
    }

    func findOrCreateDirectMessageThread(with userId: String) async throws -> MessageThread {
        guard let currentUserId = authService.userInfo?.id else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        // Use helper to find existing DM
        if let directThread = try await findExistingDirectMessageThread(with: userId) {
            return directThread
        }
        
        // If not found, create a new one
        let now = Date()
        let isFriend = authService.userInfo?.friends.contains(userId) ?? false
        
        let thread = MessageThread(
            participants: isFriend ? [currentUserId, userId] : [currentUserId],
            pendingParticipants: isFriend ? [] : [userId],
            threadName: "",
            lastMessageAt: now,
            lastReadAt: [currentUserId: now],
            ownerId: currentUserId
        )
        
        let newId = try await firestoreService.saveDocument(path: "messages", data: thread)
        
        var createdThread = thread
        createdThread.id = newId
        return createdThread
    }
}
