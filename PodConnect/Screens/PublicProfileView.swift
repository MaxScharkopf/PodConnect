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

    @Environment(\.dismiss) private var dismiss
    @State private var showUnfriendAlert = false
    @State private var isSendingRequest = false
    @State private var relationshipStatus: RelationshipStatus = .none
    @State private var isLoadingRelationship = true

    private let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)

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
                            .background(Color.white)
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
        .toolbarBackground(.hidden, for: .navigationBar)
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
            await loadRelationshipStatus()
        }
    }

    private var relationshipActionSection: some View {
        Group {
            if isLoadingRelationship {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 6, y: 3)

            } else {
                switch relationshipStatus {
                case .none:
                    Button {
                        Task {
                            isSendingRequest = true
                            do {
                                try await friendRepository.sendFriendRequest(toUID: user.uid)
                                relationshipStatus = .requestSent
                            } catch {
                                print("Failed to send request: \(error)")
                            }
                            isSendingRequest = false
                        }
                    } label: {
                        Text(isSendingRequest ? "Sending..." : "Send Request")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(IslandsBlue)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                    }
                    .disabled(isSendingRequest)

                case .requestSent:
                    Text("Pending")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.secondary)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)

                case .requestReceived:
                    HStack(spacing: 16) {
                        Button {
                            Task {
                                do {
                                    let requests = try await friendRepository.fetchIncomingRequests()
                                    if let request = requests.first(where: { $0.senderUid == user.uid }) {
                                        try await friendRepository.acceptRequest(request)
                                        relationshipStatus = .friends
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
                                .foregroundColor(IslandsBlue)
                                .cornerRadius(16)
                        }

                        Button {
                            Task {
                                do {
                                    let requests = try await friendRepository.fetchIncomingRequests()
                                    if let request = requests.first(where: { $0.senderUid == user.uid }) {
                                        try await friendRepository.declineRequest(request)
                                        relationshipStatus = .none
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
                    .shadow(color: .black.opacity(0.05), radius: 6, y: 3)

                case .friends:
                    Button {
                        showUnfriendAlert = true
                    } label: {
                        Text("Unfriend")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.red)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                    }
                }
            }
        }
    }

    private var topHeader: some View {
        VStack(spacing: 2) {
            Text(user.name.isEmpty ? user.username : user.name)
                .foregroundColor(.white)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("@\(user.username)")
                .foregroundColor(.white.opacity(0.9))
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.vertical, 14)
        .background(IslandsBlue)
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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }

    private func loadRelationshipStatus() async {
        if isOwnProfile {
            isLoadingRelationship = false
            return
        }

        if isFriend {
            relationshipStatus = .friends
            isLoadingRelationship = false
            return
        }

        if isRequested {
            relationshipStatus = .requestSent
            isLoadingRelationship = false
            return
        }

        relationshipStatus = await friendRepository.getRelationshipStatus(withUID: user.uid)
        isLoadingRelationship = false
    }
}

#Preview {
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
            friendRepository: FriendRepository(firestoreService: FirestoreService())
        )
    }
}
