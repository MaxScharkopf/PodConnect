//
//  HomeViewModel.swift
//  PodConnect
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var pendingRequestCount: Int = 0
    @Published var errorMessage: String = ""

    private let friendRepository: FriendRepository

    init(friendRepository: FriendRepository) {
        self.friendRepository = friendRepository
    }

    var hasNotifications: Bool {
        pendingRequestCount > 0
    }

    func loadNotifications() async {
        errorMessage = ""

        do {
            let requests = try await friendRepository.fetchIncomingRequests()
            pendingRequestCount = requests.count
        } catch {
            errorMessage = "Failed to load notifications."
            print("HomeViewModel loadNotifications error: \(error)")
        }
    }
}
