//
//  ChatView.swift
//  PodConnect
//
//  Created by Noah Hester on 3/30/26.
//

import SwiftUI

struct ChatView: View {
    // Database interaction structure
    private var messageRepository: MessageRepository
    // Reference to the specific message thread we are viewing
    private let messageThread: MessageThread
    // Reference to the authentication service for checking sender ID
    @ObservedObject var authService: AuthService
    
    // State variables and view model
    @StateObject private var viewModel: ChatViewModel
    @State private var currentMessage: String = ""
    
    init(messageRepository: MessageRepository, messageThread: MessageThread, authService: AuthService) {
        self.messageRepository = messageRepository
        self.messageThread = messageThread
        self.authService = authService
        
        // Construct the view model as a state object
        _viewModel = StateObject(wrappedValue: ChatViewModel(messageRepository: messageRepository, messageThreadId: messageThread.id ?? ""))
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack {
                Text(messageThread.threadName)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .font(.title)
                
                if viewModel.isLoading {
                    ProgressView()
                }
                
                ScrollView {
                    // Show messages sorted by timestamp
                    ForEach(viewModel.messages.sorted(by: { $0.timestamp < $1.timestamp })) { message in
                        
                        HStack {
                            // Render blue if sent, gray if recieved
                            if message.sender == self.authService.userInfo?.id {
                                Spacer()
                                
                                Text(message.content)
                                    .padding(10)
                                    .background(.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .padding(.horizontal)
                                    .foregroundStyle(.white)
                            }else {
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
            }
        }
        .toolbar(.hidden, for: .tabBar)
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
            .padding()
            .background(Color.secondary.colorInvert())
        }
    }
}


#Preview {
    let firestore = FirestoreService()
    let auth = AuthService(firestoreService: firestore)
    
    ChatView(messageRepository: MessageRepository(firestoreService: firestore, authService: auth), messageThread: MessageThread(id: "messageThreadID", participants: [], threadName: "The Dev Team", unread: 5), authService: auth)
}
