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
    let currentUID: String

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
            return isFriend
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
    }

    private var topHeader: some View {
        VStack(spacing: 4) {
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
        .padding(.vertical, 18)
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
            currentUID: "2"
        )
    }
}
