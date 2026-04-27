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
    @StateObject private var viewModel: HomeViewModel
    @State private var showConnections = false

    private let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)
    private let ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)

    init(authService: AuthService, selectedTab: Binding<Int>) {
        self.authService = authService
        _selectedTab = selectedTab
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(
                friendRepository: FriendRepository(firestoreService: FirestoreService())
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topHeader

                    ScrollView {
                        VStack(spacing: 20) {
                            if viewModel.hasNotifications {
                                notificationHubCard
                            }

                            if !viewModel.errorMessage.isEmpty {
                                Text(viewModel.errorMessage)
                                    .foregroundColor(.red)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }

                            Spacer(minLength: 30)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showConnections) {
                NavigationStack {
                    ConnectionsView(
                        authService: authService,
                        friendRepository: FriendRepository(firestoreService: FirestoreService())
                    )
                }
            }
        }
        .task {
            await viewModel.loadNotifications()
        }
    }

    private var topHeader: some View {
        HStack {
            Text("Home")
                .foregroundColor(.white)
                .font(.title)
                .fontWeight(.bold)

            Spacer()

            if viewModel.pendingRequestCount > 0 {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.white)
                        .font(.title2)

                    Text("\(viewModel.pendingRequestCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(ChannelClay)
                        .clipShape(Capsule())
                        .offset(x: 10, y: -8)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 23)
        .background(IslandsBlue)
    }

    private var notificationHubCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notification Hub")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            if viewModel.pendingRequestCount > 0 {
                Button {
                    showConnections = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pending Friend Requests")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("\(viewModel.pendingRequestCount) request\(viewModel.pendingRequestCount == 1 ? "" : "s") waiting")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }

            // Future notification rows go here, like Messages
            // Only show them when their count is greater than 0
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(IslandsBlue)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }
}

#Preview {
    HomeView(
        authService: AuthService(firestoreService: FirestoreService()),
        selectedTab: .constant(2)
    )
}
