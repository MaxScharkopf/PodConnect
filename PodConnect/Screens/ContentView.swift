//
//  ContentView.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 3/8/26.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @ObservedObject var authService: AuthService
    let firestoreService: FirestoreService
    
    @State private var selectedTab = 2
    @State private var selectedPinShareRequest: PinShareRequest?
    @StateObject private var assignmentsViewModel = AssignmentsViewModel()
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                TabView(selection: $selectedTab) {
                    
                    MapView(authService: authService, firestoreService: firestoreService, selectedPinShareRequest: $selectedPinShareRequest)
                        .tabItem {
                            Label("Map", systemImage: "map")
                        }
                        .tag(0)
                    
                    MessageView(authService: authService, firestoreService: firestoreService)
                        .tabItem {
                            Label("Messages", systemImage: "message")
                        }
                        .tag(1)
                    
                    HomeView(
                        authService: authService,
                        selectedTab: $selectedTab,
                        selectedPinShareRequest: $selectedPinShareRequest
                    )
                       .tabItem {                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(2)


                    NavigationStack {
                        CalendarView(
                            eventRepository: EventRepository(
                                firestoreService: firestoreService,
                                authService: authService
                            )
                        )
                    }
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(3)
                    
                    NavigationStack {
                        ProfileView(authService: authService,
                                    friendRepository:
                                        FriendRepository(firestoreService:
                                                            firestoreService))
                    }
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                    .tag(4)
                }
                .environmentObject(assignmentsViewModel)
            } else {
                AuthView(authService: authService)
                    .task {
                        selectedTab = 2
                    }
            }
        }
        .onChange(of: authService.isAuthenticated) { oldValue, newValue in
            if !newValue {
                selectedTab = 2
            }
        }
    }
}

#Preview {
    ContentView(authService: AuthService(firestoreService: FirestoreService()), firestoreService: FirestoreService())
}
