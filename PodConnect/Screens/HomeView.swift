//
//  HomeView.swift
//  PodConnect
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    private var authService: AuthService
    @Binding var selectedTab: Int
    @Binding var selectedPinShareRequest: PinShareRequest?
    @StateObject private var viewModel: HomeViewModel
    @State private var showNotifications = false

    private let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)
    private let ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)

    init(authService: AuthService, selectedTab: Binding<Int>, selectedPinShareRequest: Binding<PinShareRequest?>) {
        self.authService = authService
        _selectedTab = selectedTab
        _selectedPinShareRequest = selectedPinShareRequest
        
        let firestoreService = FirestoreService()

        _viewModel = StateObject(
            wrappedValue: HomeViewModel(
                friendRepository: FriendRepository(firestoreService: firestoreService),
                messageRepository: MessageRepository(
                    firestoreService: firestoreService,
                    authService: authService
                ),
                pinShareRepository: PinShareRepository(firestoreService: firestoreService)
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
            .onAppear {
                Task {
                    await viewModel.loadNotifications()
                }
            }
            .sheet(isPresented: $showNotifications) {
                NotificationSheetView(
                    viewModel: viewModel,
                    selectedTab: $selectedTab,
                    selectedPinShareRequest: $selectedPinShareRequest,
                    isPresented: $showNotifications
                )
            }
        }
    }

    private var topHeader: some View {
        HStack {
            Text("Home")
                .foregroundColor(.white)
                .font(.title)
                .fontWeight(.bold)

            Spacer()

            Button {
                showNotifications = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.white)
                        .font(.title2)

                    if viewModel.totalCount > 0 {
                        Text("\(viewModel.totalCount)")
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
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 23)
        .background(IslandsBlue)
    }
}

// MARK: - Notification Sheet

private struct NotificationSheetView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var selectedTab: Int
    @Binding var selectedPinShareRequest: PinShareRequest?
    @Binding var isPresented: Bool

    private let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)
    private let ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)

    var filteredRequests: [FriendRequest] {
        switch viewModel.activeFilter {
        case .all, .friendRequests:
            return viewModel.pendingRequests
        case .pinRequests, .messages:
            return []
        }
    }

    var filteredPins: [PinShareRequest] {
        switch viewModel.activeFilter {
        case .all, .pinRequests:
            return viewModel.pendingPinShareRequests
        case .friendRequests, .messages:
            return []
        }
    }

    var filteredThreads: [MessageThread] {
        switch viewModel.activeFilter {
        case .all, .messages:
            return viewModel.unreadThreads
        case .friendRequests, .pinRequests:
            return []
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterChips
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                Divider()

                if !viewModel.hasNotifications {
                    emptyState
                } else {
                    notificationList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(IslandsBlue)
                }
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(NotificationFilter.allCases, id: \.self) { filter in
                    let isActive = viewModel.activeFilter == filter

                    Button {
                        viewModel.activeFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(isActive ? .semibold : .regular)
                            .foregroundColor(isActive ? .white : IslandsBlue)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(isActive ? IslandsBlue : IslandsBlue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var notificationList: some View {
        List {
            if !filteredRequests.isEmpty {
                Section("Friend Requests") {
                    ForEach(filteredRequests) { request in
                        FriendRequestRow(
                            request: request,
                            sender: viewModel.requestSenders[request.senderUid],
                            onAccept: {
                                Task {
                                    await viewModel.acceptRequest(request)
                                }
                            },
                            onDecline: {
                                Task {
                                    await viewModel.declineRequest(request)
                                }
                            }
                        )
                    }
                }
            }

            if !filteredPins.isEmpty {
                Section("Pin Share Requests") {
                    ForEach(filteredPins) { request in
                        Button {
                            isPresented = false
                            selectedTab = 0
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                selectedPinShareRequest = request
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(IslandsBlue)
                                    .frame(width: 36, height: 36)
                                    .background(IslandsBlue.opacity(0.1))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(request.senderName ?? "Someone")
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Text("Wants to share \"\(request.pinName)\"")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !filteredThreads.isEmpty {
                Section("Messages") {
                    ForEach(filteredThreads) { thread in
                        Button {
                            isPresented = false
                            selectedTab = 1
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "message.fill")
                                    .foregroundColor(IslandsBlue)
                                    .frame(width: 36, height: 36)
                                    .background(IslandsBlue.opacity(0.1))
                                    .clipShape(Circle())

                                Text(thread.threadName)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "bell.slash")
                .font(.system(size: 44))
                .foregroundColor(.secondary)

            Text("No notifications")
                .font(.headline)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// MARK: - Friend Request Row

private struct FriendRequestRow: View {
    let request: FriendRequest
    let sender: UserInfo?
    let onAccept: () -> Void
    let onDecline: () -> Void

    private let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)
    private let ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(IslandsBlue.opacity(0.6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(sender?.username ?? "Unknown User")
                        .font(.body)
                        .fontWeight(.medium)

                    Text("Sent you a friend request")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 8) {
                Button("Accept") {
                    onAccept()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(IslandsBlue)
                .clipShape(Capsule())
                .buttonStyle(.borderless)

                Button("Decline") {
                    onDecline()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(ChannelClay)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(ChannelClay.opacity(0.1))
                .clipShape(Capsule())
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView(
        authService: AuthService(firestoreService: FirestoreService()),
        selectedTab: .constant(2),
        selectedPinShareRequest: .constant(nil)
    )
}
