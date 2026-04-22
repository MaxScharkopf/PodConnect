//
//  HomeView.swift
//  PodConnect
//
//  Created by Desiree Astabie on 3/11/26.
//
// Modified by: Kassidy Saffa,
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    private var authService: AuthService
    @Binding var selectedTab: Int
    
    
    init(authService: AuthService, selectedTab: Binding<Int>) {
        self.authService = authService
        _selectedTab = selectedTab
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                Spacer()
                
                Text("More features coming soon")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}
#Preview {
        HomeView(
            authService: AuthService(firestoreService: FirestoreService()),
            selectedTab: .constant(2)
        )
}
