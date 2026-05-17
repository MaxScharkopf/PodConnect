//
//  HomeView.swift
//  PodConnect
//
//  Created by Noah Hester on 3/29/26.
//
 
import SwiftUI
 
struct MessageView: View {
    // Recieve necessary services
    @ObservedObject var authService: AuthService
    private var firestoreService: FirestoreService
    private var messageRepository: MessageRepository
    private var friendRepository: FriendRepository
    @StateObject private var viewModel: MessageViewModel

    @State private var showThreadPopup = false
    @State private var navigatingToThread: MessageThread?
    @State private var isNavigatingToThread = false

    init(authService: AuthService, firestoreService: FirestoreService) {
        self.authService = authService
        self.firestoreService = firestoreService

        let messageRepository = MessageRepository(firestoreService: firestoreService, authService: authService)
        self.messageRepository = messageRepository
        self.friendRepository = FriendRepository(firestoreService: firestoreService)
        _viewModel = StateObject(wrappedValue: MessageViewModel(messageRepository: messageRepository))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack {
                    HStack{
                        Text("Messages")
                            .foregroundColor(.white)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.leading, 0)
                        
                        
                        Spacer()
                        Button(action: {
                            withAnimation { showThreadPopup = true }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.islandsBlue)
                    
                    Spacer()
                    
                    ScrollView {
                        if !viewModel.messageRequests.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Message Requests")
                                    .font(.headline)
                                    .padding(.horizontal)
                                    .padding(.top)
                                
                                ForEach(viewModel.messageRequests) { thread in
                                    NavigationLink(destination: ChatView(messageRepository: self.messageRepository, friendRepository: self.friendRepository, messageThread: thread, authService: self.authService, isRequest: true)) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 18)
                                                .fill(Color(.secondarySystemGroupedBackground))
                                                .frame(maxWidth: 400, minHeight: 65)
                                                .shadow(color: Color.black.opacity(0.07), radius: 6, y: 3)
                                                .padding(.horizontal)

                                            HStack(spacing: 12) {
                                                ThreadAvatarView(participants: thread.participants + thread.pendingParticipants, users: viewModel.users, currentUserId: authService.userInfo?.uid ?? "")
                                                    .padding(.leading, 25)

                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(thread.threadName.isEmpty ? viewModel.getParticipantSummary(for: thread) : thread.threadName)
                                                        .font(.headline)
                                                        .foregroundStyle(.primary)
                                                        .lineLimit(1)
                                                    
                                                    Text(thread.threadName.isEmpty ? ((thread.participants.count + thread.pendingParticipants.count) > 2 ? "Group Chat" : "Direct Message") : viewModel.getParticipantSummary(for: thread))
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                        .lineLimit(1)
                                                }

                                                Spacer()

                                                if let count = viewModel.unreadCounts[thread.id ?? ""], count > 0 {
                                                    Text("\(count)")
                                                        .font(.caption2.bold())
                                                        .foregroundColor(.white)
                                                        .padding(6)
                                                        .background(.red)
                                                        .clipShape(Circle())
                                                }
                                                
                                                Text("New")
                                                    .font(.caption2.bold())
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(.blue)
                                                    .foregroundColor(.white)
                                                    .clipShape(Capsule())
                                                    .padding(.trailing, 40)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            Divider().padding()
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            if !viewModel.messageThreads.isEmpty {
                                Text("Messages")
                                    .font(.headline)
                                    .padding(.horizontal)
                                    .padding(.top)
                            }
                            
                            ForEach(viewModel.messageThreads) { thread in
                                NavigationLink(destination: ChatView(messageRepository: self.messageRepository, friendRepository: self.friendRepository, messageThread: thread, authService: self.authService)) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(Color(.secondarySystemGroupedBackground))
                                            .frame(maxWidth: 400, minHeight: 65)
                                            .shadow(color: Color.black.opacity(0.07), radius: 6, y: 3)
                                            .padding(.horizontal)

                                        HStack(spacing: 12) {
                                            ThreadAvatarView(participants: thread.participants + thread.pendingParticipants, users: viewModel.users, currentUserId: authService.userInfo?.uid ?? "")
                                                .padding(.leading, 25)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(thread.threadName.isEmpty ? viewModel.getParticipantSummary(for: thread) : thread.threadName)
                                                    .font(.headline)
                                                    .foregroundStyle(.primary)
                                                    .lineLimit(1)
                                                
                                                Text(thread.threadName.isEmpty ? ((thread.participants.count + thread.pendingParticipants.count) > 2 ? "Group Chat" : "Direct Message") : viewModel.getParticipantSummary(for: thread))
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }

                                            Spacer()

                                            if let count = viewModel.unreadCounts[thread.id ?? ""], count > 0 {
                                                Text("\(count)")
                                                    .font(.caption2.bold())
                                                    .foregroundColor(.white)
                                                    .padding(6)
                                                    .background(.red)
                                                    .clipShape(Circle())
                                                    .padding(.trailing, 40)
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.bottom, 100) // Reduced padding to eliminate the gap
                    }
                    .onAppear() {
                        Task {
                            await viewModel.fetchData()
                        }
                    }
                    .refreshable {
                        await viewModel.fetchData()
                    }
                }
                .background(
                    Group {
                        if let thread = navigatingToThread {
                            NavigationLink(
                                destination: ChatView(
                                    messageRepository: messageRepository,
                                    friendRepository: friendRepository,
                                    messageThread: thread,
                                    authService: authService
                                ),
                                isActive: $isNavigatingToThread
                            ) {
                                EmptyView()
                            }
                        }
                    }
                )
                .popover(isPresented: $showThreadPopup) {
                    ThreadCreationPopup(authService: self.authService, friendRepository: self.friendRepository, viewModel: viewModel) { thread in
                        navigatingToThread = thread
                        isNavigatingToThread = true
                    }
                }
                .alert("Error", isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { _ in viewModel.errorMessage = nil }
                )) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
                VStack(){
                    Spacer()
                    Rectangle()
                        .fill(Color.islandsBlue)
                        .frame(maxWidth: .infinity, maxHeight: 120)
                }
                .ignoresSafeArea()
            }
        }
    }
}

struct AvatarView: View {
    let urlString: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let urlString,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        ProgressView()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var placeholder: some View {
        Image(systemName: "person.fill")
            .resizable()
            .scaledToFit()
            .padding(size * 0.25)
            .foregroundColor(.white)
            .background(Color.gray)
    }
}

struct ThreadAvatarView: View {
    let participants: [String]
    let users: [String: UserInfo]
    let currentUserId: String
    
    var otherParticipants: [String] {
        participants.filter { $0 != currentUserId }
    }
    
    var body: some View {
        let others = otherParticipants
        
        if others.count >= 2 {
            // Group Chat: Show 2 overlapping avatars
            ZStack(alignment: .bottomTrailing) {
                AvatarView(urlString: users[others[0]]?.profileImageURL, size: 30)
                    .offset(x: -8, y: -8)
                    .overlay(Circle().stroke(Color(.secondarySystemGroupedBackground), lineWidth: 2).offset(x: -8, y: -8))
                
                AvatarView(urlString: users[others[1]]?.profileImageURL, size: 30)
                    .overlay(Circle().stroke(Color(.secondarySystemGroupedBackground), lineWidth: 2))
            }
            .frame(width: 44, height: 44)
        } else if let firstOther = others.first {
            // 1:1 DM: Show single large avatar
            AvatarView(urlString: users[firstOther]?.profileImageURL, size: 44)
        } else {
            // No other participants (e.g., self-chat or loading): Show default
            AvatarView(urlString: nil, size: 44)
        }
    }
}
 
struct ThreadCreationPopup: View {
    var authService: AuthService
    var friendRepository: FriendRepository
    var viewModel: MessageViewModel
    var onNavigateToThread: (MessageThread) -> Void

    @State private var participants: [String] = []
    @State private var users: [String: UserInfo] = [:]
    @State private var newThreadName = ""
    @State private var showUserSearch = false
    @State private var localErrorMessage: String?
    
    @Environment(\.dismiss) var dismiss
    
    func reset() {
        newThreadName = ""
        showUserSearch = false
        participants = []
        users = [:]
        dismiss()
    }
    
    // Fetches user info for all participants in parallel, skipping already-loaded users
    func loadUsers() async {
        await withTaskGroup(of: (String, UserInfo?).self) { group in
            for userId in participants {
                guard users[userId] == nil else { continue }
                
                group.addTask {
                    let info = try? await self.authService.fetchUserInfo(userId: userId)
                    return (userId, info)
                }
            }
            for await (userId, info) in group {
                if let info { users[userId] = info }
            }
        }
    }
    
    var body: some View {
        VStack {
            ZStack {
                HStack {
                    Spacer()
                    
                    Button {
                        reset()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                    .padding()
                    .buttonStyle(.plain)
                }
                
                Text("Create New Thread")
                    .font(.headline)
                    .padding()
            }
            
            TextField("Thread Name", text: $newThreadName)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding()
            
            HStack {
                Text("Participants:")
                    .font(.title3)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Button(action: {
                    showUserSearch = true
                }) {
                    Image(systemName: "plus")
                        .padding()
                        .glassEffect()
                        .padding()
                }
            }
            
            List {
                ForEach(participants, id: \.self) { userId in
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .foregroundStyle(.secondary)
                        
                        if let user = users[userId] {
                            Text(user.username)
                        } else {
                            Text("Loading...")
                        }
                    }
                }
                .onDelete() { indexSet in
                    participants.remove(atOffsets: indexSet)
                }
            }
            
            Spacer()
            
            Button(action: {
                if let userInfo = authService.userInfo {
                    var finalParticipants = participants
                    if !finalParticipants.contains(userInfo.uid) {
                        finalParticipants.append(userInfo.uid)
                    }
                    
                    Task {
                        let success = await viewModel.createMessageThread(threadName: newThreadName, participants: finalParticipants)
                        if success {
                            reset()
                        } else {
                            localErrorMessage = viewModel.errorMessage
                            viewModel.errorMessage = nil // Clear global to avoid double alert
                        }
                    }
                }
            }) {
                Text("Create Thread")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .background(.blue)
                    .clipShape(Capsule())
                    .glassEffect()
                    .padding()
            }
        }
        .task {
            await loadUsers()
        }
        .popover(isPresented: $showUserSearch) {
            UserSearchPopup(friendRepository: self.friendRepository, participants: $participants)
        }
        // Reload users when the search popover closes, in case new participants were added
        .onChange(of: showUserSearch) { wasShowing, isShowing in
            if !isShowing {
                Task { await loadUsers() }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { localErrorMessage != nil },
            set: { _ in localErrorMessage = nil }
        )) {
            if let thread = viewModel.duplicateThread {
                Button("Go to Thread") {
                    dismiss()
                    onNavigateToThread(thread)
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: {
            Text(localErrorMessage ?? "")
        }
        .dismissKeyboardOnTap()
    }
}
 
// Popover for browsing and selecting friends to add as participants
struct UserSearchPopup: View {
    var friendRepository: FriendRepository

    @State private var friends: [UserInfo] = []
    @State private var otherUsers: [UserInfo] = []
    @State private var searchResults: [UserInfo] = []
    @State private var searchText: String = ""

    @Binding var participants: [String]

    @Environment(\.dismiss) var dismiss

    func reset() {
        friends = []
        otherUsers = []
        searchResults = []
        searchText = ""
        dismiss()
    }

    // Fetches initial data for the popup
    func loadInitialData() async {
        async let fetchedFriends = try? friendRepository.fetchFriends()
        async let fetchedOthers = try? friendRepository.fetchOtherUsers(limit: 15)
        
        self.friends = (await fetchedFriends) ?? []
        self.otherUsers = (await fetchedOthers) ?? []
    }

    func performSearch() async {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        searchResults = (try? await friendRepository.searchUsers(by: searchText)) ?? []
    }

    var body: some View {
        VStack {
            ZStack {
                HStack {
                    Spacer()

                    Button {
                        reset()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                    .padding()
                    .buttonStyle(.plain)
                }

                Text("Add Participants")
                    .font(.headline)
                    .padding()
            }

            TextField("Search all users by username...", text: $searchText)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal)
                .onChange(of: searchText) { _, _ in
                    Task { await performSearch() }
                }

            List {
                if !searchText.isEmpty {
                    Section(header: Text("All PodConnect Users")) {
                        if searchResults.isEmpty {
                            Text("No users found matching \"\(searchText)\"")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(searchResults) { user in
                                userRow(user: user)
                            }
                        }
                    }
                } else {
                    Section(header: Text("Friends")) {
                        if friends.isEmpty {
                            Text("You don't have any friends yet!")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(friends) { user in
                                userRow(user: user)
                            }
                        }
                    }

                    Section(header: Text("Other Users")) {
                        if otherUsers.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            // Filter out people who are already in the friends list to avoid duplicates
                            ForEach(otherUsers.filter { other in !friends.contains(where: { $0.uid == other.uid }) }) { user in
                                userRow(user: user)
                            }
                        }
                    }
                }
            }
        }
        .task {
            await loadInitialData()
        }
        .dismissKeyboardOnTap()
    }

    @ViewBuilder
    private func userRow(user: UserInfo) -> some View {
        HStack {
            Image(systemName: "person.crop.circle")
                .foregroundStyle(.secondary)

            Text(user.username)

            Spacer()

            // Show a checkmark if already added, otherwise show an add button
            if participants.contains(user.uid) {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(.green)
                    .imageScale(.large)
            } else {
                Button(action: {
                    participants.append(user.uid)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
 
#Preview {
    MessageView(authService: AuthService(firestoreService: FirestoreService()), firestoreService: FirestoreService())
}
