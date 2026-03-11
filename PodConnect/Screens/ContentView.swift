//
//  ContentView.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 3/8/26.
//

import SwiftUI

struct ContentView: View {
    
    @State private var selectedTab = 2
    
    var body: some View {
        
        TabView(selection: $selectedTab) {
          
            Text("Search")
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")}
                .tag(0)
            
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")}
                .tag(1)
            
            Text("Home")
                .tabItem {
                    Label("Home", systemImage: "house.fill")}
                .tag(2)
            
            Text("Messages")
                .tabItem {
                    Label("Messages", systemImage: "message")}
                .tag(3)
            
            Text("Calendar")
                .tabItem {
                    Label("Calendar", systemImage: "calendar")}
                .tag(4)
            
        }
    }
}

#Preview {
    ContentView()
}
