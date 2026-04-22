//
//  ChatView.swift
//  PodConnect
//
//  Created by Noah Hester on 3/30/26.
//

import SwiftUI

struct ChatView: View {
    private var messageRepository: MessageRepository
    @State private var messageThread: MessageThread
    @ObservedObject var authService: AuthService
    @StateObject private var viewModel: ChatViewModel
    
    @State private var currentMessage: String = ""
    @State private var showSettings = false
    
    @Environment(\.dismiss) private var dismiss
    
    init(messageRepository: MessageRepository, messageThread: MessageThread, authService: AuthService) {
        self.messageRepository = messageRepository
        self.messageThread = messageThread
        self.authService = authService
        _viewModel = StateObject(wrappedValue: ChatViewModel(messageRepository: messageRepository, messageThreadId: messageThread.id ?? ""))
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
                        .font(.title)
                    
                    Spacer()
                    
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.title3)
                    }
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                
                if viewModel.isLoading {
                    ProgressView()
                }
                
                ScrollView {
                    ForEach(viewModel.messages.sorted(by: { $0.timestamp < $1.timestamp })) { message in
                        HStack {
                            // Align sent messages to the right in blue, received to the left in gray
                            if message.sender == self.authService.userInfo?.id {
                                Spacer()
                                
                                Text(message.content)
                                    .padding(10)
                                    .background(.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .padding(.horizontal)
                                    .foregroundStyle(.white)
                            } else {
                                Text(message.content)
                                    .padding(10)
                                    .background(Color.secondary.colorInvert())
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .padding(.horizontal)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .defaultScrollAnchor(.bottom)
            }
        }
        .dismissKeyboardOnTap()
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
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
            .background(Color(.systemGray4).opacity(0.8).ignoresSafeArea())
            .dismissKeyboardOnTap()
        }
        .popover(isPresented: $showSettings) {
            SettingsView(authService: authService, messageThread: $messageThread, viewModel: viewModel) {
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
    
    @ObservedObject var viewModel: ChatViewModel
    
    @Binding private var messageThread: MessageThread
    
    @State private var threadName: String
    @State private var participants: [String]
    @State private var users: [String: UserInfo] = [:]
    @State private var showUserSearch: Bool = false
    
    var onThreadDeleted: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    init(authService: AuthService, messageThread: Binding<MessageThread>, viewModel: ChatViewModel, onThreadDeleted: @escaping () -> Void) {
        self._messageThread = messageThread
        self.authService = authService
        // Seed local state from the current thread so edits don't apply until saved
        self._threadName = State(initialValue: messageThread.wrappedValue.threadName)
        self._participants = State(initialValue: messageThread.wrappedValue.participants)
        self.viewModel = viewModel
        self.onThreadDeleted = onThreadDeleted
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
    
    func reset() {
        dismiss()
    }
    
    var body: some View {
        Group {
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
                    Text("Edit Thread")
                        .font(.headline)
                        .padding()
                }
                
                TextField("Thread Name", text: $threadName)
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
                    ForEach(participants.filter { $0 != authService.userInfo?.uid }, id: \.self) { userId in
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
                    .onDelete { indexSet in
                        participants.remove(atOffsets: indexSet)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    if let threadId = messageThread.id {
                        Task {
                            await viewModel.updateMessageThread(threadId: threadId, threadName: threadName, participants: participants)
                            // Reflect changes in the parent ChatView without a refetch
                            messageThread.threadName = threadName
                            messageThread.participants = participants
                            reset()
                        }
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
                
                Button(action: {
                    if let info = authService.userInfo {
                        // Remove the current user from participants
                        participants.removeAll { $0 == info.uid }
                        users[info.uid] = nil
                        
                        Task {
                            if let threadId = messageThread.id {
                                // Delete the thread entirely if no participants remain, otherwise just update it
                                if participants.isEmpty {
                                    await viewModel.deleteMessageThread(threadId: threadId)
                                } else {
                                    await viewModel.updateMessageThread(threadId: threadId, threadName: threadName, participants: participants)
                                    messageThread.threadName = threadName
                                    messageThread.participants = participants
                                }
                            }
                            reset()
                            onThreadDeleted()
                        }
                    }
                }) {
                    Text("Delete Thread")
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
        .task { await loadUsers() }
        .dismissKeyboardOnTap()
        .popover(isPresented: $showUserSearch) {
            UserSearchPopup(authService: self.authService, participants: $participants)
        }
        // Reload users when the search popover closes, in case new participants were added
        .onChange(of: showUserSearch) { _, isShowing in
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
    }
}

#Preview {
    let firestore = FirestoreService()
    let auth = AuthService(firestoreService: firestore)
    
    ChatView(messageRepository: MessageRepository(firestoreService: firestore, authService: auth), messageThread: MessageThread(id: "messageThreadID", participants: [], threadName: "The Dev Team"), authService: auth)
}
