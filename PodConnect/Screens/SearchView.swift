//
//  SearchView.swift
//  PodConnect
//
//  Created by Desiree Astabie on 4/7/26.
//


import SwiftUI
import FirebaseAuth

struct SearchView: View {
    private var authService: AuthService
    private let firestoreService: FirestoreService

    @State private var searchText = ""
    @State private var searchResults: [UserInfo] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var requestedUserIds: Set<String> = []

    @FocusState private var isSearchFieldFocused: Bool

    init(authService: AuthService, firestoreService: FirestoreService) {
        self.authService = authService
        self.firestoreService = firestoreService
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {

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
            .navigationTitle("Search")
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

        do {
            searchResults = try await firestoreService.searchUsers(by: trimmedSearch)
        } catch {
            errorMessage = "Failed to search users."
        }

        isLoading = false
    }

    func sendFriendRequest(to receiverUid: String) async {
        guard let senderUid = authService.currentUser?.uid else { return }

        errorMessage = ""

        do {
            try await firestoreService.sendFriendRequest(
                senderUid: senderUid,
                receiverUid: receiverUid
            )
        } catch {
            if !error.localizedDescription.contains("already") {
                errorMessage = error.localizedDescription
            }
        }
        
        requestedUserIds.insert(receiverUid)
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
    SearchView(
        authService: AuthService(firestoreService: FirestoreService()),
        firestoreService: FirestoreService()
    )
}
