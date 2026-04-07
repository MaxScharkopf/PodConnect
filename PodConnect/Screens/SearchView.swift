//
//  SearchView.swift
//  PodConnect
//
//  Created by Desiree Astabie on 4/7/26.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SearchView: View {

    @StateObject private var viewModel: FriendViewModel
    @State private var searchText = ""

    init(firestoreService: FirestoreService) {
        let repo = FriendRepository(firestoreService: firestoreService)
        let vm = FriendViewModel(friendRepository: repo)
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                HStack {
                    TextField("Search by username", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button("Search") {
                        Task {
                            await viewModel.searchUser(username: searchText)
                        }
                    }
                    .disabled(searchText.isEmpty)
                }
                .padding(.horizontal)

                if viewModel.isLoading {
                    ProgressView()
                }

                if !viewModel.searchErrorMessage.isEmpty {
                    Text(viewModel.searchErrorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                if let user = viewModel.searchResults {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.username)
                                .font(.headline)
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        relationshipButton(for: user)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .task {
                        await viewModel.checkRelationshipStatus(withUID: user.uid)
                    }

                    if !viewModel.sendErrorMessage.isEmpty {
                        Text(viewModel.sendErrorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Search")
        }
    }

    @ViewBuilder
    private func relationshipButton(for user: UserInfo) -> some View {
        if viewModel.relationshipStatus == .none {
            Button("Add Friend") {
                Task {
                    await viewModel.sendFriendRequest(toUID: user.uid)
                    await viewModel.checkRelationshipStatus(withUID: user.uid)
                }
            }
            .buttonStyle(.borderedProminent)
        } else if viewModel.relationshipStatus == .requestSent {
            Text("Request Sent")
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray)
                .cornerRadius(8)
        } else {
            Text("Friends")
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green)
                .cornerRadius(8)
        }
    }
}

#Preview {
    SearchView(firestoreService: FirestoreService())
}
