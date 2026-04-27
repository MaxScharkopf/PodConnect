//
//  ProfileView.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 3/28/26.
//

//
//  ProfileView.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 3/28/26.
//

import SwiftUI
import FirebaseAuth
import PhotosUI

struct ProfileView: View {
    @ObservedObject var authService: AuthService
    @StateObject private var viewModel: FriendViewModel

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImageData: Data?
    @State private var profileImageURL: String?
    @State private var isUploadingProfileImage = false

    @State private var email = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var name = ""

    @State private var selectedClubs: [String] = []
    @State private var selectedClasses: [String] = []
    @State private var clubOptions: [String] = []

    @State private var isEditing = false
    @State private var errorMessage = ""
    @State private var currentUID = ""
    @State private var isLoadingProfile = true

    @FocusState private var bioFieldFocused: Bool
    @FocusState private var usernameFieldFocused: Bool
    @FocusState private var nameFieldFocused: Bool
    
    @State private var classesVisibility: VisibilityLevel = .public
    @State private var clubsVisibility: VisibilityLevel = .public

    private let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)

    let classes = [
        "COMP 150", "COMP 162", "COMP 232", "COMP 262", "COMP 350",
        "COMP 362", "COMP 354", "COMP 429", "MATH 240", "MATH 300", "ENGL 101"
    ]

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
                    if isLoadingProfile {
                        VStack(spacing: 10) {
                            ProgressView()
                            Text("Loading profile...")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding()
                    } else {
                        VStack(spacing: 20) {
                            profileHeaderSection

                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }

                            if isEditing {
                                editSection
                                saveProfileCard
                            } else {
                                profileInfoCard
                                connectionsCard
                                actionCard
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
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadClubOptions()

            for _ in 0..<10 {
                if authService.userInfo != nil {
                    await loadProfile()
                    break
                }
                try? await Task.sleep(nanoseconds: 200_000_000)
            }

            if isLoadingProfile {
                print("ProfileView: userInfo still not ready after waiting.")
                isLoadingProfile = false
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard newItem != nil else { return }
            Task {
                await handleSelectedPhoto()
            }
        }
    }

    private var topHeader: some View {
        HStack {
            Text("Profile")
                .foregroundColor(.white)
                .font(.title)
                .fontWeight(.bold)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 23)
        .background(IslandsBlue)
    }

    private var profileHeaderSection: some View {
        VStack(spacing: 14) {
            profileImageSection

            VStack(spacing: 4) {
                Text(name.isEmpty ? " " : name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(username.isEmpty ? " " : "@\(username)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.vertical, 24)
        .background(IslandsBlue)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }

    private var editSection: some View {
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
                    Text("Name")
                        .font(.headline)

                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .focused($nameFieldFocused)
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
                        ForEach(clubOptions, id: \.self) { club in
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

                    Picker("Clubs Visibility", selection: $clubsVisibility) {
                        ForEach(VisibilityLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
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

                    Picker("Classes Visibility", selection: $classesVisibility) {
                        ForEach(VisibilityLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        }
    }

    private var saveProfileCard: some View {
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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }

    private var profileInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }

    private var connectionsCard: some View {
        NavigationLink(
            destination: ConnectionsView(
                authService: authService,
                friendRepository: viewModel.friendRepository
            )
        ) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connections")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Friends, requests, and search users")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var actionCard: some View {
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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }

    private var profileImageSection: some View {
        VStack(spacing: 10) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let profileImageData,
                           let uiImage = UIImage(data: profileImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else if let profileImageURL,
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

                    Circle()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .foregroundColor(IslandsBlue)
                                .font(.system(size: 12, weight: .semibold))
                        )
                }
            }

            if isUploadingProfileImage {
                ProgressView()
                    .tint(.white)
            }
        }
    }

    func handleSelectedPhoto() async {
        guard let item = selectedPhotoItem else { return }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                errorMessage = "Failed to load selected image."
                return
            }

            profileImageData = data
            isUploadingProfileImage = true

            guard let uid = Auth.auth().currentUser?.uid else {
                errorMessage = "User not authenticated."
                isUploadingProfileImage = false
                return
            }

            let imageURL = try await authService.uploadProfileImage(data: data, uid: uid)
            profileImageURL = imageURL
            try await authService.updateProfileImageURL(uid: uid, imageURL: imageURL)
        } catch {
            errorMessage = error.localizedDescription
        }

        isUploadingProfileImage = false
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
        nameFieldFocused = false
    }

    func loadProfile() async {
        guard let userInfo = authService.userInfo else {
            print("ProfileView: userInfo not ready yet.")
            return
        }
        
        print("classes:", userInfo.classes)
        print("clubs:", userInfo.clubs)
        print("classesVisibility:", userInfo.classesVisibility.rawValue)
        print("clubsVisibility:", userInfo.clubsVisibility.rawValue)
        
        email = userInfo.email
        username = userInfo.username
        name = userInfo.name
        bio = userInfo.bio
        currentUID = userInfo.uid
        selectedClubs = userInfo.clubs
        selectedClasses = userInfo.classes
        profileImageURL = userInfo.profileImageURL
        classesVisibility = userInfo.classesVisibility
        clubsVisibility = userInfo.clubsVisibility
        isLoadingProfile = false
        
    }

    func saveProfile() async {
        guard !currentUID.isEmpty else { return }
        let uid = currentUID

        let profile = UserInfo(
            id: uid,
            username: username,
            username_lowercase: username.lowercased(),
            name: name,
            classes: selectedClasses,
            clubs: selectedClubs,
            friends: [],
            email: email,
            uid: uid,
            bio: bio,
            profileImageURL: profileImageURL,
            classesVisibility: classesVisibility,
            clubsVisibility: clubsVisibility
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

    func loadClubOptions() async {
        do {
            let profileRepo = ProfileRepository(firestoreService: FirestoreService())
            clubOptions = try await profileRepo.fetchClubOptions()
        } catch {
            print("Failed to load clubs: \(error)")
        }
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
