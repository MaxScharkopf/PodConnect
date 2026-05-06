//
//  ChatView.swift
//  PodConnect
//
//  Created by Noah Hester on 3/30/26.
//

import SwiftUI

struct ChatView: View {
    var ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)
    var IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)
    @State private var participants: [String]
    @State private var users: [String: UserInfo] = [:]
    // Database interaction structure
    private var messageRepository: MessageRepository
    private var friendRepository: FriendRepository
    @State private var messageThread: MessageThread
    @ObservedObject var authService: AuthService
    @StateObject private var viewModel: ChatViewModel

    @State private var currentMessage: String = ""
    @State private var showSettings = false
    @State private var isRequest: Bool

    @Environment(\.dismiss) private var dismiss

    init(messageRepository: MessageRepository, friendRepository: FriendRepository, messageThread: MessageThread, authService: AuthService, isRequest: Bool = false) {
        self.messageRepository = messageRepository
        self.friendRepository = friendRepository
        self.messageThread = messageThread
        self.isRequest = isRequest
        
        var combinedParticipants = messageThread.participants
        combinedParticipants.append(contentsOf: messageThread.pendingParticipants)
        self._participants = State(initialValue: combinedParticipants)
        
        self.authService = authService
        _viewModel = StateObject(wrappedValue: ChatViewModel(messageRepository: messageRepository, messageThreadId: messageThread.id ?? ""))
    }
    
    // Fetch user info for all participants in parallel
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
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.semibold))
                    }
                    
                    Spacer()
                    
                    Text(messageThread.threadName)
                        .foregroundColor(.white)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.leading, 0)
                    
                    Spacer()
                    
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.title3)
                    }
                }
                .padding()
                .background(IslandsBlue)
                .foregroundColor(.white)
                
                if viewModel.isLoading {
                    ProgressView()
                }
                
                if isRequest {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 80))
                            .foregroundStyle(IslandsBlue)
                            .padding()
                        
                        Text("Message Request")
                            .font(.title2.bold())
                        
                        Text("You've been invited to join \"\(messageThread.threadName)\".\nAccept to see the message history and start chatting.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        ForEach(viewModel.messages.sorted(by: { $0.timestamp < $1.timestamp })) { message in
                            let isMe = message.sender == self.authService.userInfo?.uid
                            let senderUser = users[message.sender]

                            HStack(alignment: .center, spacing: 8) {
                                if isMe {
                                    Spacer()

                                    Text(message.content)
                                        .font(.body)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(IslandsBlue)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 22))
                                        .frame(maxWidth: 260, alignment: .trailing)
                                } else {
                                    AvatarView(urlString: senderUser?.profileImageURL, size: 42)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(senderUser?.name ?? "Unknown")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 10)

                                        Text(message.content)
                                            .font(.body)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color(.systemGray6))
                                            .foregroundStyle(.primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 22))
                                            .frame(maxWidth: 260, alignment: .leading)
                                    }

                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .defaultScrollAnchor(.bottom)
                }
            }
            VStack(){
                Spacer()
                Rectangle()
                    .fill(IslandsBlue)
                    .frame(maxWidth: .infinity, maxHeight: 110)
            }
            .ignoresSafeArea()
        }
        .onChange(of: viewModel.messages.count) { _, _ in
            if !isRequest {
                Task { try? await messageRepository.markThreadAsRead(threadId: messageThread.id ?? "") }
            }
        }
        .task {
            await loadUsers()
            if !isRequest {
                try? await messageRepository.markThreadAsRead(threadId: messageThread.id ?? "")
            }
        }
        .onDisappear {
            if !isRequest {
                Task {
                    try? await messageRepository.markThreadAsRead(threadId: messageThread.id ?? "")
                }
            }
        }
        .dismissKeyboardOnTap()
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            if isRequest {
                HStack(spacing: 20) {
                    Button(action: {
                        Task {
                            if let threadId = messageThread.id {
                                try? await messageRepository.joinMessageThread(threadId: threadId)
                                isRequest = false
                            }
                        }
                    }) {
                        Text("Join Chat")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    
                    Button(action: {
                        Task {
                            if let threadId = messageThread.id {
                                try? await messageRepository.declineMessageThread(threadId: threadId)
                                dismiss()
                            }
                        }
                    }) {
                        Text("Ignore")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.red)
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            } else {
                HStack {
                    TextField("Message...", text: $currentMessage)
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 50))
                        .glassEffect()
                    
                    Button(action: {
                        Task {
                            if !currentMessage.isEmpty {
                                await viewModel.sendMessage(messageContent: currentMessage)
                                currentMessage = ""
                            }
                        }
                    }) {
                        Image(systemName: "arrow.up")
                            .padding()
                            .background(.blue)
                            .clipShape(Circle())
                            .foregroundStyle(.white)
                            .glassEffect()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .dismissKeyboardOnTap()
            }
        }
        .popover(isPresented: $showSettings) {
            SettingsView(authService: authService, friendRepository: friendRepository, messageThread: $messageThread, viewModel: viewModel) {
                showSettings = false
                dismiss()
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
    }
}

// Popover for editing thread name, managing participants, and leaving or deleting the thread
struct SettingsView: View {
    var authService: AuthService
    var friendRepository: FriendRepository

    @ObservedObject var viewModel: ChatViewModel

    @Binding private var messageThread: MessageThread

    @State private var threadName: String
    @State private var participants: [String]
    @State private var pendingParticipants: [String]
    @State private var users: [String: UserInfo] = [:]
    @State private var showUserSearch: Bool = false

    var onThreadDeleted: () -> Void

    @Environment(\.dismiss) private var dismiss

    init(authService: AuthService, friendRepository: FriendRepository, messageThread: Binding<MessageThread>, viewModel: ChatViewModel, onThreadDeleted: @escaping () -> Void) {
        self._messageThread = messageThread
        self.authService = authService
        self.friendRepository = friendRepository
        // Seed local state from the current thread so edits don't apply until saved
        self._threadName = State(initialValue: messageThread.wrappedValue.threadName)
        self._participants = State(initialValue: messageThread.wrappedValue.participants)
        self._pendingParticipants = State(initialValue: messageThread.wrappedValue.pendingParticipants)
        self.viewModel = viewModel
        self.onThreadDeleted = onThreadDeleted
    }
    
    // Fetches user info for all participants in parallel, skipping already-loaded users
    func loadUsers() async {
        let allIds = participants + pendingParticipants
        await withTaskGroup(of: (String, UserInfo?).self) { group in
            for userId in allIds {
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
    
    func reset() {
        dismiss()
    }
    
    var body: some View {
        VStack {
            settingsHeader
            threadNameField
            participantsSection
            Spacer()
            saveButton
            deleteButton
        }
        .task { await loadUsers() }
        .dismissKeyboardOnTap()
        .popover(isPresented: $showUserSearch) {
            UserSearchPopup(friendRepository: self.friendRepository, participants: $pendingParticipants)
        }
        .onChange(of: showUserSearch) { _, isShowing in
            if !isShowing { Task { await loadUsers() } }
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

    private var settingsHeader: some View {
        ZStack {
            HStack {
                Spacer()
                Button { reset() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .padding()
                .buttonStyle(.plain)
            }
            Text("Edit Thread")
                .font(.headline)
                .padding()
        }
    }

    private var threadNameField: some View {
        TextField("Thread Name", text: $threadName)
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
            .padding()
    }

    private var participantsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Participants:")
                    .font(.title3)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Button(action: { showUserSearch = true }) {
                    Image(systemName: "plus")
                        .padding()
                        .glassEffect()
                        .padding()
                }
            }
            List {
                Section(header: Text("Active")) {
                    ForEach(participants.filter { $0 != authService.userInfo?.uid }, id: \.self) { userId in
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .foregroundStyle(.secondary)
                            Text(users[userId]?.username ?? "Loading...")
                        }
                    }
                    .onDelete { indexSet in participants.remove(atOffsets: indexSet) }
                }

                if !pendingParticipants.isEmpty {
                    Section(header: Text("Pending")) {
                        ForEach(pendingParticipants, id: \.self) { userId in
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .foregroundStyle(.secondary)
                                    .opacity(0.5)
                                Text(users[userId]?.username ?? "Loading...")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { indexSet in pendingParticipants.remove(atOffsets: indexSet) }
                    }
                }
            }
        }
    }

    private var saveButton: some View {
        Button(action: {
            guard let threadId = messageThread.id else { return }
            Task {
                // Update the repository with both arrays
                try? await viewModel.updateMessageThreadWithPending(threadId: threadId, threadName: threadName, participants: participants, pendingParticipants: pendingParticipants)
                messageThread.threadName = threadName
                messageThread.participants = participants
                messageThread.pendingParticipants = pendingParticipants
                reset()
            }
        }) {
            Text("Save Changes")
                .padding()
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .background(.blue)
                .clipShape(Capsule())
                .glassEffect()
                .padding()
        }
    }

    private var deleteButton: some View {
        Button(action: {
            guard let info = authService.userInfo else { return }
            participants.removeAll { $0 == info.uid }
            users[info.uid] = nil
            Task {
                if let threadId = messageThread.id {
                    if participants.isEmpty && pendingParticipants.isEmpty {
                        await viewModel.deleteMessageThread(threadId: threadId)
                    } else {
                        await viewModel.updateMessageThreadWithPending(threadId: threadId, threadName: threadName, participants: participants, pendingParticipants: pendingParticipants)
                        messageThread.threadName = threadName
                        messageThread.participants = participants
                        messageThread.pendingParticipants = pendingParticipants
                    }
                }
                reset()
                onThreadDeleted()
            }
        }) {
            Text("Leave Thread")
                .padding()
                .frame(maxWidth: .infinity)
                .foregroundColor(.red)
                .background(.red.secondary)
                .clipShape(Capsule())
                .glassEffect()
                .padding()
        }
    }
}

#Preview {
    let firestore = FirestoreService()
    let auth = AuthService(firestoreService: firestore)
    
    ChatView(messageRepository: MessageRepository(firestoreService: firestore, authService: auth), friendRepository: FriendRepository(firestoreService: firestore), messageThread: MessageThread(id: "messageThreadID", participants: [], pendingParticipants: [], threadName: "The Dev Team"), authService: auth)
}
