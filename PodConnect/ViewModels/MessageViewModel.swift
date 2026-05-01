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
    @Published var messageRequests: [MessageThread] = []
    @Published var unreadCounts: [String: Int] = [:]
    @Published var users: [String: UserInfo] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(messageRepository: MessageRepository) {
        self.messageRepository = messageRepository
        
        Task { await fetchData() }
    }

    func fetchData() async {
        self.isLoading = true
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchMessageThreads() }
            group.addTask { await self.fetchMessageRequests() }
        }
        await fetchAllUnreadCounts()
        await fetchAllParticipants()
        self.isLoading = false
    }

    func fetchAllParticipants() async {
        let allThreads = messageThreads + messageRequests
        var allParticipantIds = Set<String>()
        for thread in allThreads {
            allParticipantIds.formUnion(thread.participants)
            allParticipantIds.formUnion(thread.pendingParticipants)
        }
        
        // Skip current user and already loaded users
        if let currentId = messageRepository.getUserId() {
            allParticipantIds.remove(currentId)
        }
        
        await withTaskGroup(of: (String, UserInfo?).self) { group in
            for id in allParticipantIds {
                guard users[id] == nil else { continue }
                group.addTask {
                    let user = await self.messageRepository.fetchUser(uid: id)
                    return (id, user)
                }
            }
            
            for await (id, user) in group {
                if let user = user {
                    self.users[id] = user
                }
            }
        }
    }

    func getParticipantSummary(for thread: MessageThread) -> String {
        let currentUserId = messageRepository.getUserId()
        let allIds = thread.participants + thread.pendingParticipants
        let otherIds = allIds.filter { $0 != currentUserId }
        
        let names = otherIds.compactMap { users[$0]?.name ?? users[$0]?.username }
        
        if names.isEmpty {
            return "No other participants"
        }
        
        return names.joined(separator: ", ")
    }
    
    func fetchMessageThreads() async {
        do {
            // Retrieve user message threads
            let messageThreads = try await messageRepository.fetchMessageThreads()
            
            // Set the message threads for view access
            self.messageThreads = messageThreads
            self.errorMessage = nil
        }catch {
            // Set error message
            errorMessage = error.localizedDescription
        }
    }

    func fetchMessageRequests() async {
        do {
            let requests = try await messageRepository.fetchMessageRequests()
            self.messageRequests = requests
            self.errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchAllUnreadCounts() async {
        guard let userId = messageRepository.getUserId() else { return }
        
        await withTaskGroup(of: (String, Int).self) { group in
            for thread in messageThreads {
                if let threadId = thread.id {
                    group.addTask {
                        let count = (try? await self.messageRepository.fetchUnreadCount(threadId: threadId, lastReadAt: thread.lastReadAt?[userId])) ?? 0
                        return (threadId, count)
                    }
                }
            }
            
            for await (threadId, count) in group {
                self.unreadCounts[threadId] = count
            }
        }
    }
    
    func createMessageThread(threadName: String, participants: [String]) async {
        isLoading = true
        
        do {
            try await messageRepository.createMessageThread(threadName: threadName, participants: participants)
            await fetchData()
            errorMessage = nil
        }catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func joinThread(threadId: String) async {
        isLoading = true
        do {
            try await messageRepository.joinMessageThread(threadId: threadId)
            await fetchData()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func declineThread(threadId: String) async {
        isLoading = true
        do {
            try await messageRepository.declineMessageThread(threadId: threadId)
            await fetchData()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
