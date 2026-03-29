//
//  MessageRepository.swift
//  PodConnect
//
//  Created by Noah Hester on 3/27/26.
//

import FirebaseAuth
internal import FirebaseFirestoreInternal

final class MessageRepository {
    private let firestoreService: FirestoreService
    private let authService: AuthService
    
    init(firestoreService: FirestoreService, authService: AuthService) {
        self.firestoreService = firestoreService
        self.authService = authService
    }
    
    func fetchMessageThreads() async throws -> [MessageThread] {
        // We want to fetch the message threads pertaining to this specific user
        
        // Check if the user is logged in
        guard let userId = authService.currentUser?.uid else {
            return []
        }
        
        // Filter for the message threads that have the current user in them
        let messageThreads: [MessageThread] = try await firestoreService.fetchCollection(path: "messages") { collection in
            collection.whereField("participants", arrayContains: userId)
        }
        
        return messageThreads
    }
    
    func sendMessage(threadId: String, message: Message) {
        
    }
}
