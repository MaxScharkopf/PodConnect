//
//  HomeView.swift
//  PodConnect
//
//  Created by Noah Hester on 3/29/26.
//
 
import SwiftUI
 
struct MessageView: View {
    var ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)
    var IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)
    // Recieve necessary services
    @ObservedObject var authService: AuthService
    private var firestoreService: FirestoreService
    private var messageRepository: MessageRepository
    private var friendRepository: FriendRepository
    @StateObject private var viewModel: MessageViewModel

    @State private var showThreadPopup = false

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
                Color(.systemBackground).ignoresSafeArea()
                
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
                    .background(IslandsBlue)
                    
                    Spacer()
                    
                    ScrollView {
                        if !viewModel.messageRequests.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Message Requests")
                                    .font(.headline)
                                    .padding(.horizontal)
                                    .padding(.top)
                                
                                ForEach(viewModel.messageRequests) { thread in
                                    NavigationLink(destination: ChatView(messageRepository: self.messageRepository, friendRepository: self.friendRepository, messageThread: thread, authService: self.authService, isRequest: true)) {
                                        ZStack {
                                            
                                            Rectangle()
                                                .fill(Color.white.opacity(0.8))
                                                .frame(maxWidth: 400, maxHeight: 55)
                                                .clipShape(Capsule())
                                                .shadow(color: Color.black.opacity(0.1), radius: 5)
                                                .padding(.horizontal)

                                            HStack {
                                                if thread.threadName.isEmpty {
                                                    Text(viewModel.getParticipantSummary(for: thread))
                                                        .padding(20)
                                                        .font(.headline)
                                                        .foregroundStyle(.primary)
                                                        .lineLimit(1)
                                                        .padding(.leading)
                                                }else {
                                                    VStack(alignment: .leading, spacing: 0) {
                                                        Text(thread.threadName)
                                                            .font(.headline)
                                                            .foregroundStyle(.primary)
                                                            .lineLimit(1)
                                                            .padding(.leading)
                                                        
                                                        Text(viewModel.getParticipantSummary(for: thread))
                                                            .font(.caption2)
                                                            .foregroundStyle(.secondary)
                                                            .lineLimit(1)
                                                            .padding(.leading)
                                                            .padding(.trailing, 32)
                                                    }
                                                    .padding(20)
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
                                                    .font(.caption)
                                                    .padding(6)
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

                        VStack(alignment: .leading) {
                            if !viewModel.messageThreads.isEmpty {
                                Text("Messages")
                                    .font(.headline)
                                    .padding(.horizontal)
                                    .padding(.top)
                            }
                            
                            ForEach(viewModel.messageThreads) { thread in
                                NavigationLink(destination: ChatView(messageRepository: self.messageRepository, friendRepository: self.friendRepository, messageThread: thread, authService: self.authService)) {
                                    ZStack {
                                        Rectangle()
                                            .fill(.white)
                                            .frame(maxWidth: 400, maxHeight: 55)
                                            .clipShape(Capsule())
                                            .shadow(color: Color.black.opacity(0.2), radius: 5)
                                            .padding(.horizontal)

                                        HStack {
                                            if thread.threadName.isEmpty {
                                                Text(viewModel.getParticipantSummary(for: thread))
                                                    .padding(20)
                                                    .font(.headline)
                                                    .foregroundStyle(.primary)
                                                    .lineLimit(1)
                                                    .padding(.leading)
                                            }else {
                                                VStack(alignment: .leading, spacing: 0) {
                                                    Text(thread.threadName)
                                                        .font(.headline)
                                                        .foregroundStyle(.primary)
                                                        .lineLimit(1)
                                                        .padding(.leading)
                                                    
                                                    Text(viewModel.getParticipantSummary(for: thread))
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                        .lineLimit(1)
                                                        .padding(.leading)
                                                        .padding(.trailing, 32)
                                                }
                                                .padding(20)
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
                    }
                    .onAppear() {
                        Task {
                            await viewModel.fetchData()
                        }
                    }
                    .refreshable {
                        await viewModel.fetchData()
                    }
                    
                    Spacer()
                }
                .popover(isPresented: $showThreadPopup) {
                    ThreadCreationPopup(authService: self.authService, friendRepository: self.friendRepository, viewModel: viewModel)
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
                        .fill(IslandsBlue)
                        .frame(maxWidth: .infinity, maxHeight: 120)
                }
                .ignoresSafeArea()
            }
        }
    }
}
 
// Popover for creating a new message thread with a name and participants
struct ThreadCreationPopup: View {
    var authService: AuthService
    var friendRepository: FriendRepository
    var viewModel: MessageViewModel

    @State private var participants: [String] = []
    @State private var users: [String: UserInfo] = [:]
    @State private var newThreadName = ""
    @State private var showUserSearch = false
    
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
                    // Include the current user as a participant before creating the thread
                    participants.append(userInfo.uid)
                    
                    Task {
                        await viewModel.createMessageThread(threadName: newThreadName, participants: participants)
                        reset()
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
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
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
