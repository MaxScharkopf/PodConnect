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

    @State private var email = ""
    @State private var username = ""
    @State private var bio = ""

    @State private var selectedClubs: [String] = []
    @State private var selectedClasses: [String] = []

    @State private var isEditing = false
    @State private var errorMessage = ""

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
            selectedClubs = userInfo.clubs
            selectedClasses = userInfo.classes
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Saves profile changes through AuthService.
    func saveProfile() async {
        guard let uid = authService.currentAuthenticatedUser()?.uid else { return }

        let profile = UserInfo(
            id: uid,
            username: username,
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
}

#Preview {
    NavigationView {
        ProfileView(authService: AuthService(firestoreService: FirestoreService()))
    }
}
