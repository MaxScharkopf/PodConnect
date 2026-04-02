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
    // Holds messaging database interaction repository
    private var messageRepository: MessageRepository
    // View model for state updates
    @StateObject private var viewModel: MessageViewModel
    
    init(authService: AuthService, firestoreService: FirestoreService) {
        self.authService = authService
        self.firestoreService = firestoreService
        
        // Create the repository
        let messageRepository = MessageRepository(firestoreService: firestoreService, authService: authService)
        
        self.messageRepository = messageRepository
        
        // Create the view model
        _viewModel = StateObject(wrappedValue: MessageViewModel(messageRepository: messageRepository))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gray.opacity(0.5).ignoresSafeArea()
                
                VStack {
                    Text("Messages")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .font(.title)
                    
                    Spacer()
                    
                    ScrollView {
                        // Render each text thread
                        ForEach(viewModel.messageThreads) { thread in
                            NavigationLink(destination: ChatView(messageRepository: self.messageRepository, messageThread: thread, authService: self.authService)) {
                                ZStack {
                                    Rectangle()
                                        .fill(.white)
                                        .frame(maxWidth: .infinity)
                                    
                                    HStack {
                                        
                                        Text(thread.threadName)
                                            .padding(20)
                                            .font(.headline)
                                            .foregroundStyle(.black)
                                        
                                        Spacer()
                                        
                                        if(thread.unread > 0) {
                                            Text("\(thread.unread)")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding(10)
                                                .background(.blue)
                                                .clipShape(Circle())
                                                .padding(10)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.fetchMessageThreads()
                    }
                    
                    Spacer()
                }
            }
        }
    }
}


#Preview {
    MessageView(authService: AuthService(firestoreService: FirestoreService()), firestoreService: FirestoreService())
}
