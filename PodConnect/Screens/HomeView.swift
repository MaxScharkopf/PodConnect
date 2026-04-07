//
//  HomeView.swift
//  PodConnect
//
//  Created by Desiree Astabie on 3/11/26.
//
// Modified by: Kassidy Saffa,
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    private var authService: AuthService
    private let firestoreService = FirestoreService()

    @State private var searchText = ""
    @State private var searchResults: [UserInfo] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var requestedUserIds: Set<String> = []

    @FocusState private var isSearchFieldFocused: Bool

    init(authService: AuthService) {
        self.authService = authService
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {

                HStack {
                    Spacer()

                    NavigationLink(destination: ProfileView(authService: authService)) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.circle")
                            Text("Profile")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Find Classmates")
                        .font(.headline)

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        TextField("Search users by username", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($isSearchFieldFocused)
                            .onSubmit {
                                Task {
                                    await performSearch()
                                    isSearchFieldFocused = false
                                }
                            }

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                searchResults = []
                                errorMessage = ""
                                successMessage = ""
                                isSearchFieldFocused = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    Button("Search") {
                        Task {
                            await performSearch()
                            isSearchFieldFocused = false
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                if !successMessage.isEmpty {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.footnote)
                }

                ScrollView {
                    VStack(spacing: 12) {
                        if searchResults.isEmpty && !searchText.isEmpty && !isLoading {
                            Text("No users found.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 12)
                        }

                        ForEach(searchResults) { user in
                            if user.uid != authService.currentUser?.uid {
                                UserSearchResultCard(
                                    user: user,
                                    isRequested: requestedUserIds.contains(user.uid),
                                    onSendRequest: {
                                        Task {
                                            await sendFriendRequest(to: user.uid)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .contentShape(Rectangle())
            .onTapGesture {
                isSearchFieldFocused = false
            }
        }
    }

    func performSearch() async {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearch.isEmpty else {
            searchResults = []
            errorMessage = ""
            return
        }

        isLoading = true
        errorMessage = ""
        successMessage = ""

        do {
            searchResults = try await firestoreService.searchUsers(by: trimmedSearch)
        } catch {
            errorMessage = "Failed to search users."
        }

        isLoading = false
    }

    func sendFriendRequest(to receiverUid: String) async {
        guard let senderUid = authService.currentUser?.uid else {
            return
        }

        errorMessage = ""
        successMessage = ""

        do {
            try await firestoreService.sendFriendRequest(
                senderUid: senderUid,
                receiverUid: receiverUid
            )
            requestedUserIds.insert(receiverUid)
            successMessage = "Friend request sent."
            isSearchFieldFocused = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct UserSearchResultCard: View {
    let user: UserInfo
    let isRequested: Bool
    let onSendRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(user.username)
                .font(.headline)

            Text(user.email)
                .font(.footnote)
                .foregroundColor(.gray)

            if !user.bio.isEmpty {
                Text(user.bio)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            Button(isRequested ? "Requested" : "Send Request") {
                onSendRequest()
            }
            .disabled(isRequested)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    HomeView(authService: AuthService(firestoreService: FirestoreService()))
}