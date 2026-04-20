//
//  MessageViewModel.swift
//  PodConnect
//
//  Created by Noah Hester on 3/27/26.
//

import Combine
import Foundation

@MainActor
class MessageViewModel: ObservableObject {
    // The message repository for abstract database interaction
    private var messageRepository: MessageRepository
    
    // Holds the message threads of the user that is signed in
    @Published var messageThreads: [MessageThread] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(messageRepository: MessageRepository) {
        self.messageRepository = messageRepository
        
        Task { await fetchMessageThreads() }
    }
    
    func fetchMessageThreads() async {
        // Set loading flag
        self.isLoading = true
        
        do {
            // Retrieve user message threads
            let messageThreads = try await messageRepository.fetchMessageThreads()
            
            // Set the message threads for view access
            self.messageThreads = messageThreads
            
            // Set loading and error
            self.isLoading = false
            self.errorMessage = nil
        }catch {
            // Set error message
            errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func createMessageThread(threadName: String, participants: [String]) async {
        isLoading = true
        
        do {
            try await messageRepository.createMessageThread(threadName: threadName, participants: participants)
            isLoading = false
            errorMessage = nil
        }catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
