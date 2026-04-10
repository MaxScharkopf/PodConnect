//
//  ProfileView.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 3/28/26.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @ObservedObject var authService: AuthService
    @StateObject private var viewModel: FriendViewModel

    init(authService: AuthService, friendRepository: FriendRepository) {
        _authService = ObservedObject(wrappedValue: authService)
        _viewModel = StateObject(wrappedValue: FriendViewModel(friendRepository: friendRepository))
    }

    @State private var email = ""
    @State private var username = ""
    @State private var bio = ""

    @State private var selectedClubs: [String] = []
    @State private var selectedClasses: [String] = []

    @State private var isEditing = false
    @State private var errorMessage = ""
    
    @State private var currentUID = ""
    @State private var selectedSocialTab = 0
    
    @State private var searchText = ""
    @State private var searchResults: [UserInfo] = []
    @State private var isLoadingSearch = false
    @State private var searchErrorMessage = ""
    @State private var requestedUserIds: Set<String> = []
    @FocusState private var isSearchFieldFocused: Bool

    @FocusState private var bioFieldFocused: Bool
    @FocusState private var usernameFieldFocused: Bool

    let clubs = ["Anthropology Club", "CI Bird Club", "CI Hiking Club", "CI Roller-Skating Club", "Data Science Club", "Programming Club", "TableTope Games Club", "Union de Hermanos"]
    let classes = ["COMP 150", "COMP 162", "COMP 232", "COMP 262", "COMP 350", "COMP 362", "COMP 354", "COMP 429", "MATH 240", "MATH 300", "ENGL 101"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 80))

                Text(email)
                    .foregroundColor(.gray)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if isEditing {
                    VStack(spacing: 12) {

                        VStack(alignment: .leading, spacing: 16) {

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Username")
                                    .font(.headline)

                                TextField("Username", text: $username)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($usernameFieldFocused)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Bio")
                                    .font(.headline)

                                TextEditor(text: $bio)
                                    .frame(height: 120)
                                    .padding(8)
                                    .background(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.4))
                                    )
                                    .cornerRadius(8)
                                    .focused($bioFieldFocused)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Clubs")
                                    .font(.headline)

                                Menu {
                                    ForEach(clubs, id: \.self) { club in
                                        Button {
                                            toggleSelection(club, in: &selectedClubs)
                                        } label: {
                                            HStack {
                                                Text(club)
                                                if selectedClubs.contains(club) {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedClubs.isEmpty ? "Select clubs" : selectedClubs.joined(separator: ", "))
                                            .foregroundColor(selectedClubs.isEmpty ? .gray : .primary)
                                            .lineLimit(2)

                                        Spacer()

                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(10)
                                }
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Classes")
                                    .font(.headline)

                                Menu {
                                    ForEach(classes, id: \.self) { course in
                                        Button {
                                            toggleSelection(course, in: &selectedClasses)
                                        } label: {
                                            HStack {
                                                Text(course)
                                                if selectedClasses.contains(course) {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedClasses.isEmpty ? "Select classes" : selectedClasses.joined(separator: ", "))
                                            .foregroundColor(selectedClasses.isEmpty ? .gray : .primary)
                                            .lineLimit(2)

                                        Spacer()

                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)

                        VStack(spacing: 0) {
                            Button("Save Profile") {
                                dismissKeyboard()
                                Task {
                                    await saveProfile()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                } else {
                    VStack(spacing: 12) {

                        VStack(alignment: .leading, spacing: 16) {

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Username")
                                    .font(.headline)
                                Text(username.isEmpty ? "Not set" : username)
                                    .foregroundColor(.primary)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Bio")
                                    .font(.headline)
                                Text(bio.isEmpty ? "No bio yet" : bio)
                                    .foregroundColor(.primary)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Clubs")
                                    .font(.headline)
                                Text(selectedClubs.isEmpty ? "None selected" : selectedClubs.joined(separator: ", "))
                                    .foregroundColor(.primary)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Classes")
                                    .font(.headline)
                                Text(selectedClasses.isEmpty ? "None selected" : selectedClasses.joined(separator: ", "))
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        
                        // Connections section
                        VStack(spacing: 8) {
                            Picker("", selection: $selectedSocialTab) {
                                Text("Friends").tag(0)
                                Text("Requests").tag(1)
                                Text("Search").tag(2)
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: .infinity)

                            ScrollView {
                                VStack(spacing: 0) {
                                    if selectedSocialTab == 0 {
                                        if viewModel.friends.isEmpty {
                                            Text("No friends yet")
                                                .foregroundColor(.secondary)
                                                .padding()
                                        } else {
                                            ForEach(viewModel.friends) { friend in
                                                Text(friend.username)
                                                    .padding(.horizontal)
                                                    .padding(.vertical, 10)
                                                Divider()
                                            }
                                        }
                                    } else if selectedSocialTab == 1 {
                                        Text("Requests — coming soon")
                                            .foregroundColor(.secondary)
                                            .padding()
                                    } else {
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack(spacing: 8) {
                                                HStack {
                                                    Image(systemName: "magnifyingglass")
                                                        .foregroundColor(.gray)
                                                    TextField("Search users...", text: $searchText)
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
                                                            searchErrorMessage = ""
                                                            isSearchFieldFocused = false
                                                        } label: {
                                                            Image(systemName: "xmark.circle.fill")
                                                                .foregroundColor(.gray)
                                                        }
                                                    }
                                                }
                                                .padding(10)
                                                .background(Color(.systemBackground))
                                                .cornerRadius(12)
                                                
                                                Button("Search") {
                                                    Task {
                                                        await performSearch()
                                                        isSearchFieldFocused = false
                                                    }
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .background(Color(.systemBackground))
                                                .cornerRadius(12)
                                            }
                                            
                                            if isLoadingSearch {
                                                HStack {
                                                    Spacer()
                                                    ProgressView()
                                                    Spacer()
                                                }
                                            }
                                            
                                            if !searchErrorMessage.isEmpty {
                                                Text(searchErrorMessage)
                                                    .foregroundColor(.red)
                                                    .font(.footnote)
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
                                        .padding(.horizontal, 8)
                                        .padding(.top, 8)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                        }
                        
                        VStack(spacing: 0) {
                            Button("Edit Profile") {
                                isEditing = true
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            
                            Divider()
                            
                            NavigationLink(destination: AccountSettingsView()) {
                                Text("Account Settings")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .foregroundColor(.primary)
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                }
                
                Button("Sign Out") {
                    do {
                        try authService.signOut()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
                .foregroundColor(.red)
                
                Spacer(minLength: 30)
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture {
                dismissKeyboard()
            }
        }
        .navigationTitle("Profile")
        .task {
            await loadProfile()
            await viewModel.fetchFriends()
        }
    }
    
    func toggleSelection(_ item: String, in array: inout [String]) {
        if array.contains(item) {
            array.removeAll { $0 == item }
        } else {
            array.append(item)
        }
    }
    
    func dismissKeyboard() {
        bioFieldFocused = false
        usernameFieldFocused = false
    }
    
    // Loads the user's profile data through AuthService.
    func loadProfile() async {
        do {
            guard let userInfo = authService.userInfo else {
                throw AuthError.generic
            }
            
            email = userInfo.email
            username = userInfo.username
            bio = userInfo.bio
            currentUID = userInfo.uid
            selectedClubs = userInfo.clubs
            selectedClasses = userInfo.classes
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Saves profile changes through AuthService.
    func saveProfile() async {
        guard !currentUID.isEmpty else { return }
                let uid = currentUID

        let profile = UserInfo(
            id: uid,
            username: username,
            username_lowercase: username.lowercased(),
            classes: selectedClasses,
            clubs: selectedClubs,
            email: email,
            uid: uid,
            bio: bio
        )

        do {
            try await authService.updateUserProfile(profile)
            isEditing = false
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "Something went wrong."
        } catch {
            errorMessage = error.localizedDescription
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
        do {
            searchResults = try await viewModel.friendRepository.searchUsers(by: trimmed)
            for user in searchResults {
                let status = await viewModel.friendRepository.getRelationshipStatus(withUID: user.uid)
                if status == .requestSent || status == .friends {
                    requestedUserIds.insert(user.uid)
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
        } catch {
            if !error.localizedDescription.contains("already") {
                searchErrorMessage = error.localizedDescription
            }
        }
        requestedUserIds.insert(receiverUid)
    }
}

#Preview {
    NavigationView {
        ProfileView(
            authService: AuthService(firestoreService: FirestoreService()),
            friendRepository: FriendRepository(firestoreService: FirestoreService())
        )
    }
}
