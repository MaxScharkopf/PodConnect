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
    
    private var messageListenerTask: Task<Void, Never>?
    
    init(messageRepository: MessageRepository, messageThreadId: String) {
        self.messageRepository = messageRepository
        self.messageThreadId = messageThreadId
        
        listenForMessages()
    }
    
    deinit {
        messageListenerTask?.cancel()
    }
    
    private func listenForMessages() {
        // Set loading flag
        self.isLoading = true
        
        messageListenerTask = Task {
            do {
                // Retrieve user message threads
                let stream = messageRepository.messageFetchStream(threadId: self.messageThreadId)
                
                for try await messages in stream {
                    // Set the message threads for view access
                    self.messages = messages
                    
                    // Set loading and error
                    self.isLoading = false
                    self.errorMessage = nil
                }
            } catch {
                // Set error message
                errorMessage = error.localizedDescription
                self.isLoading = false
            }
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
            self.isLoading = false
        }
    }
    
    func updateMessageThread(threadId: String, threadName: String, participants: [String]) async {
        isLoading = true
        
        do {
            try await messageRepository.updateMessageThread(threadId: threadId, threadName: threadName, participants: participants)
            isLoading = false
            errorMessage = nil
        }catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func deleteMessageThread(threadId: String) async {
        isLoading = true
        
        do {
            try await messageRepository.deleteMessageThread(threadId: threadId)
            isLoading = false
            errorMessage = nil
        }catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
