//
//  HomeView.swift
//  PodConnect
//
//  Created by Noah Hester on 3/29/26.
//
 
import SwiftUI
 
struct MessageView: View {
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
                    HStack {
                        Text("Messages")
                            .foregroundColor(.white)
                            .font(.title)
                            .padding()
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation { showThreadPopup = true }
                        }) {
                            Image(systemName: "plus")
                                .padding()
                                .glassEffect()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemRed))
                    
                    Spacer()
                    
                    ScrollView {
                        ForEach(viewModel.messageThreads) { thread in
                            NavigationLink(destination: ChatView(messageRepository: self.messageRepository, friendRepository: self.friendRepository, messageThread: thread, authService: self.authService)) {
                                ZStack {
                                    Rectangle()
                                        .fill(.tertiary)
                                        .frame(maxWidth: .infinity)
                                    
                                    HStack {
                                        Text(thread.threadName)
                                            .padding(20)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onAppear() {
                        Task {
                            await viewModel.fetchMessageThreads()
                        }
                    }
                    .refreshable {
                        await viewModel.fetchMessageThreads()
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

    @Binding var participants: [String]

    @Environment(\.dismiss) var dismiss

    func reset() {
        friends = []
        dismiss()
    }

    // Fetches friends from the friends collection via FriendRepository
    func loadFriends() async {
        friends = (try? await friendRepository.fetchFriends()) ?? []
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

                Text("Add Friend")
                    .font(.headline)
                    .padding()
            }

            Spacer()

            if friends.isEmpty {
                Text("You don't have any friends, go make some new ones!")
                    .multilineTextAlignment(.center)
                Spacer()
            } else {
                List {
                    ForEach(friends) { user in
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
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            await loadFriends()
        }
    }
}
 
#Preview {
    MessageView(authService: AuthService(firestoreService: FirestoreService()), firestoreService: FirestoreService())
}
