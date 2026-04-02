//
//  HomeView.swift
//  PodConnect
//
//  Created by Desiree Astabie on 3/11/26.
//
// Modified by: Kassidy Saffa,
//


import SwiftUI

struct HomeView: View {
    private var authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // Top Bar (keep this)
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
                .padding(.horizontal)
                
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


struct FeedRow: View {
    let icon: String
    let label: String
    let detail: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .bold()
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .navigationTitle("Home")
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView(authService: AuthService(firestoreService: FirestoreService()))
}
