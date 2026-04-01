//
//  ContentView.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 3/8/26.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    
    @State private var selectedTab = 2
    @State private var isAuthenticated = Auth.auth().currentUser != nil
    
    var body: some View {
        Group {
            if isAuthenticated {
                TabView(selection: $selectedTab) {
                    
                    Text("Search")
                        .tabItem {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                        .tag(0)
                    
                    MapView()
                        .tabItem {
                            Label("Map", systemImage: "map")
                        }
                        .tag(1)
                    
                    HomeView(onSignOut: {
                        isAuthenticated = false
                        selectedTab = 2
                    })
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(2)
                    
                    Text("Messages")
                        .tabItem {
                            Label("Messages", systemImage: "message")
                        }
                        .tag(3)
                    
                    Text("Calendar")
                        .tabItem {
                            Label("Calendar", systemImage: "calendar")
                        }
                        .tag(4)
                }
            } else {
                AuthView(onAuthenticated: {
                    isAuthenticated = true
                })
            }
        }
    }
}

#Preview {
    ContentView()
}
