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
    @Published var participants: [User] = []
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
}
