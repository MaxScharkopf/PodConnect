//
//  PublicProfileView.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 4/25/26.
//

import Foundation
import SwiftUI

struct PublicProfileView: View {
    let user: UserInfo
    let isFriend: Bool
    let isRequested: Bool
    let currentUID: String
    let friendRepository: FriendRepository
    let messageRepository: MessageRepository
    let authService: AuthService

    @Environment(\.dismiss) private var dismiss
    @State private var showUnfriendAlert = false
    @State private var isSendingRequest = false
    @State private var relationshipStatus: RelationshipStatus = .none
    @State private var isLoadingRelationship = true
    @State private var relationshipListenerTask: Task<Void, Never>?

    @State private var navigatingToChat = false
    @State private var chatThread: MessageThread?
    @State private var isCreatingThread = false

    private var isChatRequest: Bool {
        chatThread?.pendingParticipants.contains(currentUID) ?? false
    }

    private var isOwnProfile: Bool {
        user.uid == currentUID
    }

    private func canView(_ visibility: VisibilityLevel) -> Bool {
        if isOwnProfile { return true }

        switch visibility {
        case .public:
            return true
        case .friendsOnly:
            return relationshipStatus == .friends || isFriend
        case .private:
            return false
        }
    }

    private var shouldShowBio: Bool {
        !user.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var shouldShowClubs: Bool {
        canView(user.clubsVisibility) && !user.clubs.isEmpty
    }

    private var shouldShowClasses: Bool {
        canView(user.classesVisibility) && !user.classes.isEmpty
    }

    private var hasVisibleContent: Bool {
        shouldShowBio || shouldShowClubs || shouldShowClasses
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                topHeader

                ScrollView {
                    VStack(spacing: 20) {
                        profileImageSection

                        if !isOwnProfile {
                            relationshipActionSection
                        }

                        if shouldShowBio {
                            infoCard(title: "Bio", content: user.bio)
                        }

                        if shouldShowClubs {
                            infoCard(title: "Clubs", content: user.clubs.joined(separator: ", "))
                        }

                        if shouldShowClasses {
                            infoCard(title: "Classes", content: user.classes.joined(separator: ", "))
                        }

                        if !hasVisibleContent {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("No profile details available")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                        }

                        Spacer(minLength: 30)
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Unfriend \(user.username)?", isPresented: $showUnfriendAlert) {
            Button("Unfriend", role: .destructive) {
                Task {
                    try? await friendRepository.unfriend(uid: user.uid)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .task {
            startRelationshipListener()
        }
        .onDisappear {
            relationshipListenerTask?.cancel()
            relationshipListenerTask = nil
        }
    }

    private var relationshipActionSection: some View {
        VStack(spacing: 16) {
            if isLoadingRelationship {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 6, y: 3)

            } else {
                HStack(spacing: 16) {
                    messageButton

                    switch relationshipStatus {
                    case .none:
                        Button {
                            Task {
                                isSendingRequest = true
                                do {
                                    try await friendRepository.sendFriendRequest(toUID: user.uid)
                                } catch {
                                    print("Failed to send request: \(error)")
                                }
                                isSendingRequest = false
                            }
                        } label: {
                            Text(isSendingRequest ? "Sending..." : "Send Request")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.islandsBlue)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                        }
                        .disabled(isSendingRequest)

                    case .requestSent:
                        Button {
                            Task {
                                do {
                                    try await friendRepository.cancelFriendRequest(toUID: user.uid)
                                } catch {
                                    print("Failed to cancel request: \(error)")
                                }
                            }
                        } label: {
                            Text("Pending")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.secondary)
                                .cornerRadius(16)
                        }

                    case .requestReceived:
                        HStack(spacing: 12) {
                            Button {
                                Task {
                                    do {
                                        let requests = try await friendRepository.fetchIncomingRequests()
                                        if let request = requests.first(where: { $0.senderUid == user.uid }) {
                                            try await friendRepository.acceptRequest(request)
                                        }
                                    } catch {
                                        print("Failed to accept request: \(error)")
                                    }
                                }
                            } label: {
                                Text("Accept")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .foregroundColor(Color.islandsBlue)
                                    .cornerRadius(16)
                            }

                            Button {
                                Task {
                                    do {
                                        let requests = try await friendRepository.fetchIncomingRequests()
                                        if let request = requests.first(where: { $0.senderUid == user.uid }) {
                                            try await friendRepository.declineRequest(request)
                                        }
                                    } catch {
                                        print("Failed to decline request: \(error)")
                                    }
                                }
                            } label: {
                                Text("Decline")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.12))
                                    .foregroundColor(.red)
                                    .cornerRadius(16)
                            }
                        }

                    case .friends:
                        Button {
                            showUnfriendAlert = true
                        } label: {
                            Image(systemName: "person.badge.minus")
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .foregroundColor(.red)
                                .cornerRadius(16)
                        }
                    }
                }
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            }
        }
        .background(
            Group {
                if let chatThread = chatThread {
                    NavigationLink(
                        destination: ChatView(
                            messageRepository: messageRepository,
                            friendRepository: friendRepository,
                            messageThread: chatThread,
                            authService: authService,
                            isRequest: isChatRequest
                        ),
                        isActive: $navigatingToChat
                    ) {
                        EmptyView()
                    }
                }
            }
        )
    }

    private var messageButton: some View {
        Button {
            Task {
                isCreatingThread = true
                do {
                    chatThread = try await messageRepository.findOrCreateDirectMessageThread(with: user.uid)
                    navigatingToChat = true
                } catch {
                    print("Failed to start chat: \(error)")
                }
                isCreatingThread = false
            }
        } label: {
            HStack {
                if isCreatingThread {
                    ProgressView()
                        .tint(.white)
                        .padding(.trailing, 4)
                } else {
                    Image(systemName: "message.fill")
                }
                Text("Message")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.islandsBlue)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .disabled(isCreatingThread)
    }

    private var topHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .semibold))
            }

            Spacer()

            VStack(spacing: 1) {
                Text(user.name.isEmpty ? user.username : user.name)
                    .foregroundColor(.white)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(1)

                Text("@\(user.username)")
                    .foregroundColor(.white.opacity(0.9))
                    .font(.subheadline)
                    .lineLimit(1)
            }

            Spacer()

            Color.clear
                .frame(width: 18, height: 18)
        }
        .padding(.horizontal)
        .frame(height: 66)
        .background(Color.islandsBlue)
    }

    private var profileImageSection: some View {
        VStack(spacing: 10) {
            Group {
                if let profileImageURL = user.profileImageURL,
                   let url = URL(string: profileImageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .empty:
                            ProgressView()
                        case .failure:
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray)
                                .padding(8)
                        @unknown default:
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray)
                                .padding(8)
                        }
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .padding(8)
                }
            }
            .frame(width: 110, height: 110)
            .background(Color(.systemGray6))
            .clipShape(Circle())
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private func infoCard(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(content)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }

    private func startRelationshipListener() {
        if isOwnProfile {
            relationshipStatus = .none
            isLoadingRelationship = false
            return
        }

        relationshipListenerTask?.cancel()

        relationshipListenerTask = Task {
            do {
                let stream = friendRepository.relationshipStatusStream(withUID: user.uid)
                var firstValue = true

                for try await status in stream {
                    relationshipStatus = status
                    if firstValue {
                        isLoadingRelationship = false
                        firstValue = false
                    }
                }
            } catch {
                print("Failed to listen for relationship status: \(error)")
                isLoadingRelationship = false
            }
        }
    }
}

#Preview {
    let firestore = FirestoreService()
    let auth = AuthService(firestoreService: firestore)
    
    NavigationView {
        PublicProfileView(
            user: UserInfo(
                id: "1",
                username: "maxwell",
                username_lowercase: "maxwell",
                name: "Max Scharkopf",
                classes: ["COMP 150", "COMP 162"],
                clubs: ["Associated Students Inc."],
                friends: [],
                email: "max@example.com",
                uid: "1",
                bio: "Hello!",
                profileImageURL: nil,
                classesVisibility: .public,
                clubsVisibility: .friendsOnly
            ),
            isFriend: true,
            isRequested: false,
            currentUID: "2",
            friendRepository: FriendRepository(firestoreService: firestore),
            messageRepository: MessageRepository(firestoreService: firestore, authService: auth),
            authService: auth
        )
    }
}
