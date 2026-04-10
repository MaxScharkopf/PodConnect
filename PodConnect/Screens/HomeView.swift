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
        NavigationView {
            VStack(spacing: 20) {
                
                HStack {
                    Spacer()
                    NavigationLink(destination: ProfileView(authService: authService)) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.circle")
                            Text("Profile")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    Button {
                        selectedTab = 0
                    } label: {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .font(.title2)
                                .padding(.trailing, 8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Find a")
                                    .font(.headline)
                                Text("Classmate")
                                    .font(.headline)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .frame(height: 120)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                    .foregroundColor(.primary)
                }
                
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
