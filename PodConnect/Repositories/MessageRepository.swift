//
//  MessageRepository.swift
//  PodConnect
//
//  Created by Noah Hester on 3/27/26.
//

import FirebaseAuth
internal import FirebaseFirestoreInternal

// Store core functions for messaging capabilities
final class MessageRepository {
    private var firestoreService: FirestoreService
    private var authService: AuthService
    
    init(firestoreService: FirestoreService, authService: AuthService) {
        self.firestoreService = firestoreService
        self.authService = authService
    }
    
    func fetchMessageThreads() async throws -> [MessageThread] {
        // Check if the user is logged in
        guard let userId = authService.userInfo?.id else {
            return []
        }
        
        // Filter for the message threads that have the current user in them
        let messageThreads: [MessageThread] = try await firestoreService.fetchCollection(path: "messages") { collection in
            collection.whereField("participants", arrayContains: userId)
        }
        
        return messageThreads
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
        
        let message = Message(content: messageContent, sender: userId, timestamp: Date())
        
        try await firestoreService.saveDocument(path: "messages/\(threadId)/messages", data: message)
    }
    
    func createMessageThread(threadName: String, participants: [String]) async throws {
        // Check if the user is logged in
        guard let userId = authService.userInfo?.id else {
            return
        }
        
        let thread = MessageThread(participants: participants, threadName: threadName)
        
        try await firestoreService.saveDocument(path: "messages", data: thread)
    }
    
    func updateMessageThread(threadId: String, threadName: String, participants: [String]) async throws {
        // Check if the user is logged in
        guard let userId = authService.userInfo?.id else {
            return
        }
        
        let thread = MessageThread(participants: participants, threadName: threadName)
        
        try await firestoreService.updateDocument(path: "messages", documentId: threadId, data: thread)
    }
    
    func deleteMessageThread(threadId: String) async throws {
        // Check if the user is logged in
        guard let userId = authService.userInfo?.id else {
            return
        }
        
        try await firestoreService.removeDocument(path: "messages", documentId: threadId)
    }
}
