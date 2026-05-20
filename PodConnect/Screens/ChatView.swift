//
//  ChatView.swift
//  PodConnect
//
//  Created by Noah Hester on 3/30/26.
//

import SwiftUI

struct ChatView: View {
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

    @State private var editingMessageId: String?
    @State private var editingContent: String = ""
    @State private var showDeleteConfirmation = false
    @State private var messageToDelete: Message?

    @State private var dragOffset: CGFloat = 0

    @Environment(\.dismiss) private var dismiss

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private var threadTitle: String {
        if !messageThread.threadName.isEmpty {
            return messageThread.threadName
        }
        
        let currentUserId = authService.userInfo?.uid
        let allIds = messageThread.participants + messageThread.pendingParticipants
        let otherIds = allIds.filter { $0 != currentUserId }
        
        let names = otherIds.compactMap { users[$0]?.name ?? users[$0]?.username }
        
        if names.isEmpty {
            return "New Chat"
        }
        
        return names.joined(separator: ", ")
    }

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
                    
                    Text(threadTitle)
                        .foregroundColor(.white)
                        .font(.title)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if !isRequest {
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape")
                                .font(.title3)
                        }
                    }
                }
                .padding()
                .background(Color.islandsBlue)
                .foregroundColor(.white)
                
                if viewModel.isLoading {
                    ProgressView()
                }
                
                if isRequest {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.islandsBlue)
                            .padding()
                        
                        Text("Message Request")
                            .font(.title2.bold())
                        
                        Text("You've been invited to join \"\(threadTitle)\".\nAccept to see the message history and start chatting.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    GeometryReader { geometry in
                        ScrollView {
                            VStack(spacing: 6) {
                                ForEach(viewModel.messages.sorted(by: { $0.timestamp < $1.timestamp })) { message in
                                    let isMe = message.sender == self.authService.userInfo?.uid
                                    let senderUser = users[message.sender]

                                    HStack(spacing: 0) {
                                        // Message Content
                                        HStack(alignment: .center, spacing: 8) {
                                            if isMe {
                                                Spacer()

                                                VStack(alignment: .trailing, spacing: 4) {
                                                    Text(message.content)
                                                        .font(.body)
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 10)
                                                        .background(editingMessageId == message.id ? .orange : Color.islandsBlue)
                                                        .foregroundStyle(.white)
                                                        .clipShape(RoundedRectangle(cornerRadius: 22))

                                                    if message.isEdited == true {
                                                        HStack(spacing: 4) {
                                                            Image(systemName: "pencil")
                                                            Text("edited")
                                                        }
                                                        .font(.system(size: 10, weight: .medium))
                                                        .foregroundColor(.secondary)
                                                        .padding(.trailing, 8)
                                                    }
                                                }
                                                .frame(maxWidth: 260, alignment: .trailing)
                                                .contextMenu {
                                                    Button {
                                                        editingMessageId = message.id
                                                        editingContent = message.content
                                                        currentMessage = message.content
                                                    } label: {
                                                        Label("Edit", systemImage: "pencil")
                                                    }

                                                    Button(role: .destructive) {
                                                        messageToDelete = message
                                                        showDeleteConfirmation = true
                                                    } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                            } else {
                                                AvatarView(urlString: senderUser?.profileImageURL, size: 42)

                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(senderUser?.name ?? "Unknown")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        .padding(.leading, 10)

                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(message.content)
                                                            .font(.body)
                                                            .padding(.horizontal, 16)
                                                            .padding(.vertical, 10)
                                                            .background(Color(.systemGray6))
                                                            .foregroundStyle(.primary)
                                                            .clipShape(RoundedRectangle(cornerRadius: 22))

                                                        if message.isEdited == true {
                                                            HStack(spacing: 4) {
                                                                Image(systemName: "pencil")
                                                                Text("edited")
                                                            }
                                                            .font(.system(size: 10, weight: .medium))
                                                            .foregroundColor(.secondary)
                                                            .padding(.leading, 8)
                                                        }
                                                    }
                                                    .frame(maxWidth: 260, alignment: .leading)
                                                }

                                                Spacer()
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .frame(width: geometry.size.width)

                                        // Timestamp
                                        Text(timeFormatter.string(from: message.timestamp))
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .frame(width: 65, alignment: .leading)
                                    }
                                    .offset(x: dragOffset)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .contentShape(Rectangle())
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 10, coordinateSpace: .local)
                                .onChanged { value in
                                    // Only respond if the drag is primarily horizontal to the left
                                    if value.translation.width < 0 && abs(value.translation.width) > abs(value.translation.height) {
                                        if dragOffset == 0 {
                                            UISelectionFeedbackGenerator().selectionChanged()
                                        }
                                        withAnimation(.interactiveSpring()) {
                                            dragOffset = max(value.translation.width, -65)
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        dragOffset = 0
                                    }
                                }
                        )
                        .defaultScrollAnchor(.bottom)
                    }
                }
            }
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
                                try? await messageRepository.markThreadAsRead(threadId: threadId)
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
                .background(Color.islandsBlue.ignoresSafeArea(edges: .bottom))
            } else {
                VStack(spacing: 0) {
                    if let editingId = editingMessageId {
                        HStack {
                            Text("Editing message")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Button(action: {
                                editingMessageId = nil
                                currentMessage = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.2))
                    }
                    
                    HStack(alignment: .bottom, spacing: 12) {
                        TextField(editingMessageId == nil ? "Message..." : "Edit message...", text: $currentMessage, axis: .vertical)
                            .lineLimit(1...5)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                        
                        Button(action: {
                            Task {
                                if !currentMessage.isEmpty {
                                    if let editingId = editingMessageId {
                                        await viewModel.editMessage(messageId: editingId, content: currentMessage)
                                        editingMessageId = nil
                                    } else {
                                        await viewModel.sendMessage(messageContent: currentMessage)
                                    }
                                    currentMessage = ""
                                }
                            }
                        }) {
                            Image(systemName: editingMessageId == nil ? "arrow.up" : "checkmark")
                                .font(.system(size: 20, weight: .bold))
                                .frame(width: 48, height: 48)
                                .background(.blue)
                                .clipShape(Circle())
                                .foregroundStyle(.white)
                                .glassEffect()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color.islandsBlue.ignoresSafeArea(edges: .bottom))
                .dismissKeyboardOnTap()
            }
        }
        .popover(isPresented: $showSettings) {
            SettingsView(authService: authService, friendRepository: friendRepository, messageThread: $messageThread, viewModel: viewModel) {
                showSettings = false
                dismiss()
            }
        }
        .alert("Delete Message?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let message = messageToDelete, let id = message.id {
                    Task {
                        await viewModel.deleteMessage(messageId: id)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this message? This action cannot be undone.")
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
    @State private var showTransferOwnership: Bool = false
    @State private var selectedNewOwnerId: String?

    var onThreadDeleted: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var isGroup: Bool {
        (participants.count + pendingParticipants.count) > 2 || !messageThread.threadName.isEmpty
    }

    private var isOwner: Bool {
        // In a group, follow strict ownership. In a DM, both are "owners" of the interaction.
        if !isGroup { return true }
        return messageThread.ownerId == authService.userInfo?.uid
    }

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
        .popover(isPresented: $showTransferOwnership) {
            transferOwnershipPicker
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

    private var transferOwnershipPicker: some View {
        VStack {
            Text("Select New Owner")
                .font(.headline)
                .padding()
            
            Text("You must choose a new owner before leaving the thread.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            List {
                let otherActive = participants.filter { $0 != authService.userInfo?.uid }
                ForEach(otherActive, id: \.self) { userId in
                    Button {
                        selectedNewOwnerId = userId
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text(users[userId]?.username ?? "Loading...")
                            Spacer()
                            if selectedNewOwnerId == userId {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            
            Button {
                if let newOwnerId = selectedNewOwnerId {
                    transferAndLeave(to: newOwnerId)
                }
            } label: {
                Text("Transfer & Leave")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .background(selectedNewOwnerId == nil ? Color.gray : Color.blue)
                    .clipShape(Capsule())
                    .padding()
            }
            .disabled(selectedNewOwnerId == nil)
            
            Button("Cancel", role: .cancel) {
                showTransferOwnership = false
            }
            .padding(.bottom)
        }
        .frame(minWidth: 300, minHeight: 400)
    }

    private func transferAndLeave(to newOwnerId: String) {
        guard let info = authService.userInfo, let threadId = messageThread.id else { return }
        Task {
            var updatedParticipants = participants
            updatedParticipants.removeAll { $0 == info.uid }
            
            try? await viewModel.updateMessageThreadWithPending(
                threadId: threadId,
                threadName: threadName,
                participants: updatedParticipants,
                pendingParticipants: pendingParticipants,
                ownerId: newOwnerId
            )
            
            showTransferOwnership = false
            reset()
            onThreadDeleted()
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
            .disabled(!isGroup || !isOwner) // Only owner of a GROUP can rename
    }

    private var participantsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Participants:")
                    .font(.title3)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                if isOwner { // Both "owners" in a DM can add people to make it a group
                    Button(action: { showUserSearch = true }) {
                        Image(systemName: "plus")
                            .padding()
                            .glassEffect()
                            .padding()
                    }
                }
            }
            List {
                Section(header: Text("Active")) {
                    ForEach(participants, id: \.self) { userId in
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .foregroundStyle(.secondary)
                            Text(users[userId]?.username ?? "Loading...")
                            
                            if userId == messageThread.ownerId || !isGroup {
                                Text("Owner")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.islandsBlue.opacity(0.15))
                                    .foregroundColor(Color.islandsBlue)
                                    .clipShape(Capsule())
                                    .padding(.leading, 4)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        if isOwner {
                            // Don't allow deleting yourself if you are the owner and there are others
                            // They must transfer ownership instead. 
                            // But for simplicity of this UI, we just filter the indexSet
                            let idsToDelete = indexSet.map { participants[$0] }
                            if !idsToDelete.contains(authService.userInfo?.uid ?? "") {
                                participants.remove(atOffsets: indexSet)
                            }
                        }
                    }
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
                                
                                if userId == messageThread.ownerId || !isGroup {
                                    Text("Owner")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.15))
                                        .foregroundColor(.secondary)
                                        .clipShape(Capsule())
                                        .padding(.leading, 4)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            if isOwner {
                                pendingParticipants.remove(atOffsets: indexSet)
                            }
                        }
                    }
                }
            }
        }
    }

    private var saveButton: some View {
        Group {
            if isOwner && isGroup { // Only show save for group owners (DM updates happen auto on leave/add)
                Button(action: {
                    guard let threadId = messageThread.id else { return }
                    Task {
                        // Update the repository with both arrays
                        try? await viewModel.updateMessageThreadWithPending(threadId: threadId, threadName: threadName, participants: participants, pendingParticipants: pendingParticipants, ownerId: messageThread.ownerId)
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
        }
    }

    private var deleteButton: some View {
        Button(action: {
            guard let info = authService.userInfo else { return }
            Task {
                if let threadId = messageThread.id {
                    let otherActive = participants.filter { $0 != info.uid }
                    let allOthers = otherActive + pendingParticipants
                    
                    if messageThread.ownerId == info.uid {
                        // Current user is the DB owner
                        if allOthers.isEmpty {
                            // Last person, delete everything
                            await viewModel.deleteMessageThread(threadId: threadId)
                            reset()
                            onThreadDeleted()
                        } else if !isGroup {
                            // It's a DM, auto-transfer to the other person and leave
                            if let newOwner = allOthers.first {
                                transferAndLeave(to: newOwner)
                            }
                        } else {
                            // It's a group with others, must pick a new owner
                            showTransferOwnership = true
                        }
                    } else {
                        // User is a member or DM participant but not DB owner
                        // Just leave. In a DM, since we treated them as "owner" for UI, 
                        // they still just leave here.
                        var updatedParticipants = participants
                        updatedParticipants.removeAll { $0 == info.uid }
                        try? await viewModel.updateMessageThreadWithPending(threadId: threadId, threadName: threadName, participants: updatedParticipants, pendingParticipants: pendingParticipants, ownerId: messageThread.ownerId)
                        reset()
                        onThreadDeleted()
                    }
                }
            }
        }) {
            Text(isOwner ? (isGroup ? "Leave Thread" : "Delete Chat") : "Leave Thread")
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
    
    ChatView(messageRepository: MessageRepository(firestoreService: firestore, authService: auth), friendRepository: FriendRepository(firestoreService: firestore), messageThread: MessageThread(id: "messageThreadID", participants: [], pendingParticipants: [], threadName: "The Dev Team", lastMessageAt: nil, lastReadAt: nil, ownerId: "1"), authService: auth)
}
