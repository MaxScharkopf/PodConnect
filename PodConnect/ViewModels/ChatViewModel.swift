//
//  ChatViewModel.swift
//  PodConnect
//
//  Created by Noah Hester on 3/30/26.
//

import Combine
import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    // The message repository for abstract database interaction
    private var messageRepository: MessageRepository
    // The particular thread the user is looking at
    private var messageThreadId: String
    
    // Holds the messages of the message thread
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(messageRepository: MessageRepository, messageThreadId: String) {
        self.messageRepository = messageRepository
        self.messageThreadId = messageThreadId
        
        Task { await fetchMessages() }
    }
    
    func fetchMessages() async {
        // Set loading flag
        self.isLoading = true
        
        do {
            // Retrieve user message threads
            let messages = try await messageRepository.fetchMessages(threadId: self.messageThreadId)
            
            // Set the message threads for view access
            self.messages = messages
            
            // Set loading and error
            self.isLoading = false
            self.errorMessage = nil
        }catch {
            // Set error message
            errorMessage = error.localizedDescription
        }
    }
    
    func sendMessage(messageContent: String) async {
        // Set loading flag
        self.isLoading = true
        
        do {
            // Send the message by adding a document
            try await messageRepository.sendMessage(threadId: self.messageThreadId, messageContent: messageContent)
            
            // Set loading and error
            self.isLoading = false
            self.errorMessage = nil
        }catch {
            // Set error message
            self.errorMessage = error.localizedDescription
        }
    }
}
