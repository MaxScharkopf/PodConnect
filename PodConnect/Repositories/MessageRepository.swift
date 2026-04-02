//
//  MessageRepository.swift
//  PodConnect
//
//  Created by Noah Hester on 3/27/26.
//

import FirebaseAuth
internal import FirebaseFirestoreInternal

final class MessageRepository {
    private var firestoreService: FirestoreService
    private var authService: AuthService
    
    init(firestoreService: FirestoreService, authService: AuthService) {
        self.firestoreService = firestoreService
        self.authService = authService
    }
    
    func fetchMessageThreads() async throws -> [MessageThread] {
        // We want to fetch the message threads pertaining to this specific user
        
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
        // We want to fetch the message threads pertaining to this specific user
        
        // Check if the user is logged in
        guard authService.isAuthenticated else {
            return []
        }
        
        // Filter for the message threads that have the current user in them
        let messages: [Message] = try await firestoreService.fetchCollection(path: "messages/\(threadId)/messages")
        
        return messages
    }
    
    func sendMessage(threadId: String, messageContent: String) async throws {
        // We want to fetch the message threads pertaining to this specific user
        
        // Check if the user is logged in
        guard let userId = authService.userInfo?.id else {
            return
        }
        
        let message = Message(content: messageContent, sender: userId, timestamp: Date())
        
        // Filter for the message threads that have the current user in them
        try await firestoreService.saveDocument(path: "messages/\(threadId)/messages", data: message)
    }
}
