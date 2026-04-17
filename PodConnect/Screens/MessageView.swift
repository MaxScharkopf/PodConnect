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
    
    @State private var searchText = ""
    @State private var showThreadPopup = false
    @State private var showUserSearch = false
    @State private var newThreadName = ""
    @State private var participants: [String] = []
    
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
                    HStack {
                        
                        Text("Messages")
                            .foregroundColor(.white)
                            .font(.title)
                            .padding()
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation { showThreadPopup = true }
                        })
                        {
                            Image(systemName: "plus")
                                .padding()
                                .glassEffect()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    
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
                .popover(isPresented: $showThreadPopup) {
                    VStack {
                        Text("Create New Thread")
                            .font(.headline)
                            .padding(.top)
                        
                        TextField("Thread Name", text: $newThreadName)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .padding()
                        
                        
                        Spacer()
                    }
                }
            }
        }
    }
}


#Preview {
    MessageView(authService: AuthService(firestoreService: FirestoreService()), firestoreService: FirestoreService())
}
