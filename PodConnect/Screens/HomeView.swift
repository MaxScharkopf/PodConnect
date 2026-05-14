//
//  HomeView.swift
//  PodConnect
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @ObservedObject private var authService: AuthService
    @Binding var selectedTab: Int
    @Binding var selectedPinShareRequest: PinShareRequest?
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var toDoViewModel = ToDoViewModel()
    @StateObject private var calendarViewModel: CalendarViewModel
    @EnvironmentObject var assignmentsViewModel: AssignmentsViewModel
    @State private var showNotifications = false
    @State private var showAddClass = false

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

        _calendarViewModel = StateObject(
            wrappedValue: CalendarViewModel(
                eventRepository: EventRepository(
                    firestoreService: firestoreService,
                    authService: authService
                )
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
                        VStack(spacing: 16) {
                            if !viewModel.errorMessage.isEmpty {
                                Text(viewModel.errorMessage)
                                    .foregroundColor(.red)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }

                            HStack(spacing: 14) {
                                DateTimeCardView()
                                CampusEventCardView()
                            }

                            WeatherCardView()

                            EventsCardView(selectedTab: $selectedTab, userEvents: calendarViewModel.userEvents)

                            Button {
                                showAddClass = true
                            } label: {
                                Label("Add Class to Schedule", systemImage: "plus.circle.fill")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.islandsBlue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.islandsBlue.opacity(UIScreen.main.traitCollection.userInterfaceStyle == .dark ? 0.25 : 0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            HStack {
                                Text("My Tasks")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.top, 4)

                            ToDoCardView(viewModel: toDoViewModel)
                            AssignmentsCardView()
                        }
                        .padding()
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await viewModel.loadNotifications()
                    await calendarViewModel.fetchEvents()
                }
            }
            .task(id: authService.userInfo?.id) {
                guard authService.userInfo?.id != nil else { return }
                await calendarViewModel.fetchEvents()
            }
            .sheet(isPresented: $showAddClass) {
                AddClassView { events in
                    Task { await calendarViewModel.saveEvents(events) }
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

    private var WelcomeMsg1: AttributedString {
        var welcome = AttributedString("Welcome, ")
        welcome.foregroundColor = Color.channelClay
        return welcome
    }

    private var WelcomeMsg2: AttributedString {
        let userName = authService.userInfo?.username ?? "User"
        var username = AttributedString(userName)
        username.foregroundColor = .white
        return username
    }

    private var topHeader: some View {
        HStack {
            Text(WelcomeMsg1 + WelcomeMsg2)
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
                            .background(Color.channelClay)
                            .clipShape(Capsule())
                            .offset(x: 10, y: -8)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 23)
        .background(Color.islandsBlue)
    }
}

// MARK: - Notification Sheet

private struct NotificationSheetView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var selectedTab: Int
    @Binding var selectedPinShareRequest: PinShareRequest?
    @Binding var isPresented: Bool

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

    var filteredMessageRequests: [MessageThread] {
        switch viewModel.activeFilter {
        case .all, .messages:
            return viewModel.pendingMessageRequests
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
                    .foregroundColor(.blue) // Standard blue for better system visibility
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
                            .foregroundColor(isActive ? .white : .primary) // Use primary for inactive text
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Group {
                                    if isActive {
                                        Color.islandsBlue
                                    } else {
                                        Color(.secondarySystemFill) // More visible background in dark mode
                                    }
                                }
                            )
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

            if !filteredMessageRequests.isEmpty {
                Section("Message Requests") {
                    ForEach(filteredMessageRequests) { thread in
                        Button {
                            if let threadId = thread.id {
                                Task { await viewModel.markAsRead(threadId: threadId) }
                            }
                            isPresented = false
                            selectedTab = 1
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.badge.fill")
                                    .foregroundColor(Color.islandsBlue)
                                    .frame(width: 36, height: 36)
                                    .background(Color.islandsBlue.opacity(0.1))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(thread.threadName.isEmpty ? viewModel.getParticipantSummary(for: thread) : thread.threadName)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Text("New group invitation")
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
                                    .foregroundColor(Color.islandsBlue)
                                    .frame(width: 36, height: 36)
                                    .background(Color.islandsBlue.opacity(0.1))
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
                            if let threadId = thread.id {
                                Task { await viewModel.markAsRead(threadId: threadId) }
                            }
                            isPresented = false
                            selectedTab = 1
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "message.fill")
                                    .foregroundColor(Color.islandsBlue)
                                    .frame(width: 36, height: 36)
                                    .background(Color.islandsBlue.opacity(0.1))
                                    .clipShape(Circle())

                                Text(thread.threadName.isEmpty ? viewModel.getParticipantSummary(for: thread) : thread.threadName)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color.islandsBlue.opacity(0.6))

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
                .background(Color.islandsBlue)
                .clipShape(Capsule())
                .buttonStyle(.borderless)

                Button("Decline") {
                    onDecline()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.channelClay)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.channelClay.opacity(0.1))
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
    .environmentObject(AssignmentsViewModel())
}
