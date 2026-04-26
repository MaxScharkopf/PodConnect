//
//  ConnectionsView.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 4/25/26.
//

import Foundation
import SwiftUI

struct ConnectionsView: View {
    @ObservedObject var authService: AuthService
    @StateObject private var viewModel: FriendViewModel

    @State private var searchText = ""
    @State private var searchResults: [UserInfo] = []
    @State private var isLoadingSearch = false
    @State private var searchErrorMessage = ""
    @State private var requestedUserIds: Set<String> = []
    @State private var friendUserIds: Set<String> = []
    @State private var currentUID = ""

    @State private var isSearchMode = false
    @State private var isLoadingConnections = true
    @FocusState private var isSearchFieldFocused: Bool

    private let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)

    init(authService: AuthService, friendRepository: FriendRepository) {
        _authService = ObservedObject(wrappedValue: authService)
        _viewModel = StateObject(wrappedValue: FriendViewModel(friendRepository: friendRepository))
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                topHeader

                ScrollView {
                    VStack(spacing: 20) {
                        if isLoadingConnections {
                            VStack(spacing: 10) {
                                ProgressView()
                                Text("Loading connections...")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else if isSearchMode {
                            searchSection
                        } else {
                            if !viewModel.incomingRequests.isEmpty {
                                requestsSection
                            }

                            friendsSection
                        }
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isSearchFieldFocused = false
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            isLoadingConnections = true
            currentUID = authService.userInfo?.uid ?? ""

            await viewModel.fetchFriends()
            await viewModel.fetchIncomingRequests()

            isLoadingConnections = false
        }
    }

    private var topHeader: some View {
        HStack {
            Text("Connections")
                .foregroundColor(.white)
                .font(.title)
                .fontWeight(.bold)
                .padding(.leading)

            Spacer()

            Button {
                withAnimation {
                    isSearchMode.toggle()
                }

                if !isSearchMode {
                    searchText = ""
                    searchResults = []
                    searchErrorMessage = ""
                    isSearchFieldFocused = false
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isSearchFieldFocused = true
                    }
                }
            } label: {
                Image(systemName: isSearchMode ? "xmark" : "magnifyingglass")
                    .padding()
                    .glassEffect()
            }
            .padding(.trailing, 9)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(IslandsBlue)
    }

    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Requests")
                .font(.headline)
                .foregroundColor(.primary)

            ForEach(viewModel.incomingRequests) { request in
                NavigationLink(
                    destination: RequestProfileLoaderView(
                        senderUid: request.senderUid,
                        friendRepository: viewModel.friendRepository,
                        currentUID: currentUID
                    )
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        SenderUsernameView(
                            senderUid: request.senderUid,
                            friendRepository: viewModel.friendRepository
                        )

                        HStack(spacing: 12) {
                            Button("Accept") {
                                Task {
                                    await viewModel.acceptRequest(request)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(IslandsBlue.opacity(0.12))
                            .foregroundColor(IslandsBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            Button("Decline") {
                                Task {
                                    await viewModel.declineRequest(request)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Friends")
                .font(.headline)
                .foregroundColor(.primary)

            if viewModel.friends.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.2")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)

                    Text("No friends yet")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.friends) { friend in
                        NavigationLink(
                            destination: PublicProfileView(
                                user: friend,
                                isFriend: true,
                                isRequested: false,
                                currentUID: currentUID,
                                friendRepository: viewModel.friendRepository
                            )
                        ) {
                            UserRowView(user: friend)
                                .padding()
                                .background(Color.white)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            // Search bar
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search users...", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isSearchFieldFocused)
                        .onSubmit {
                            Task { await performSearch() }
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            searchResults = []
                            searchErrorMessage = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)

                Button("Go") {
                    Task { await performSearch() }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(IslandsBlue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // Loading
            if isLoadingSearch {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            }

            // Error
            if !searchErrorMessage.isEmpty {
                Text(searchErrorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.horizontal, 4)
            }

            // Empty state
            if !isLoadingSearch &&
                searchResults.isEmpty &&
                !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                searchErrorMessage.isEmpty {

                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)

                    Text("No users found")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            }

            // Results (clean + clickable only)
            ForEach(searchResults) { user in
                if user.uid != currentUID {
                    NavigationLink(
                        destination: PublicProfileView(
                            user: user,
                            isFriend: friendUserIds.contains(user.uid),
                            isRequested: requestedUserIds.contains(user.uid),
                            currentUID: currentUID,
                            friendRepository: viewModel.friendRepository
                        )
                    ) {
                        UserRowView(user: user)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    func performSearch() async {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            searchErrorMessage = ""
            return
        }

        isLoadingSearch = true
        searchErrorMessage = ""
        requestedUserIds.removeAll()
        friendUserIds.removeAll()

        do {
            searchResults = try await viewModel.friendRepository.searchUsers(by: trimmed)

            for user in searchResults {
                let status = await viewModel.friendRepository.getRelationshipStatus(withUID: user.uid)

                if status == .requestSent {
                    requestedUserIds.insert(user.uid)
                } else if status == .friends {
                    friendUserIds.insert(user.uid)
                }
            }
        } catch {
            searchErrorMessage = "Failed to search users."
        }

        isLoadingSearch = false
    }

    func sendFriendRequest(to receiverUid: String) async {
        searchErrorMessage = ""

        do {
            try await viewModel.friendRepository.sendFriendRequest(toUID: receiverUid)
            requestedUserIds.insert(receiverUid)
        } catch {
            if !error.localizedDescription.contains("already") {
                searchErrorMessage = error.localizedDescription
            } else {
                requestedUserIds.insert(receiverUid)
            }
        }
    }
}

struct SenderUsernameView: View {
    let senderUid: String
    let friendRepository: FriendRepository

    @State private var user: UserInfo? = nil

    var body: some View {
        Group {
            if let user = user {
                HStack(spacing: 12) {
                    Group {
                        if let urlString = user.profileImageURL,
                           let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                default:
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.gray)
                                }
                            }
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.username)
                            .font(.body)
                            .fontWeight(.medium)

                        if !user.name.isEmpty {
                            Text(user.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }
            } else {
                Text("Loading...")
                    .foregroundColor(.secondary)
            }
        }
        .task {
            user = await friendRepository.fetchUser(uid: senderUid)
        }
    }
}

struct UserRowView: View {
    let user: UserInfo

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let urlString = user.profileImageURL,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(user.username)
                    .font(.body)
                    .fontWeight(.medium)

                if !user.name.isEmpty {
                    Text(user.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }
}

struct UserSearchResultCard: View {
    let user: UserInfo
    let isRequested: Bool
    let isFriend: Bool
    let onSendRequest: () -> Void
    let accentColor: Color
    let friendRepository: FriendRepository

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                profileImageView

                VStack(alignment: .leading, spacing: 6) {
                    Text(user.username)
                        .font(.headline)

                    if !user.name.isEmpty {
                        Text(user.name)
                            .foregroundColor(.primary)
                    }
                }

                Spacer()
            }

            Button(buttonTitle) {
                if isFriend {
                    Task {
                        try? await friendRepository.unfriend(uid: user.uid)
                    }
                } else if !isRequested {
                    onSendRequest()
                }
            }
            .disabled(isRequested)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(buttonBackground)
            .foregroundColor(buttonTextColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }

    private var buttonTitle: String {
        if isFriend { return "Unfriend" }
        if isRequested { return "Pending" }
        return "Send Request"
    }

    private var buttonBackground: Color {
        if isFriend || isRequested {
            return Color(.systemGray5)
        }
        return accentColor
    }

    private var buttonTextColor: Color {
        if isFriend || isRequested {
            return .secondary
        }
        return .white
    }

    private var profileImageView: some View {
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
                            .padding(6)
                    @unknown default:
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.gray)
                            .padding(6)
                    }
                }
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
                    .padding(6)
            }
        }
        .frame(width: 56, height: 56)
        .background(Color(.systemBackground))
        .clipShape(Circle())
    }
}

struct RequestProfileLoaderView: View {
    let senderUid: String
    let friendRepository: FriendRepository
    let currentUID: String

    @State private var user: UserInfo? = nil

    var body: some View {
        Group {
            if let user = user {
                PublicProfileView(
                    user: user,
                    isFriend: false,
                    isRequested: false,
                    currentUID: currentUID,
                    friendRepository: friendRepository
                )
            } else {
                ZStack {
                    Color(.systemGroupedBackground).ignoresSafeArea()

                    VStack(spacing: 10) {
                        ProgressView()
                        Text("Loading profile...")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .task {
            user = await friendRepository.fetchUser(uid: senderUid)
        }
    }
}

#Preview {
    NavigationView {
        ConnectionsView(
            authService: AuthService(firestoreService: FirestoreService()),
            friendRepository: FriendRepository(firestoreService: FirestoreService())
        )
    }
}
