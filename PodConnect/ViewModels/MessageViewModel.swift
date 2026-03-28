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
    private var messageRepository: MessageRepository
    
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(messageRepository: MessageRepository) {
        self.messageRepository = messageRepository
    }
    
    
}
