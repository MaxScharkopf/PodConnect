//
//  CalendarView.swift
//  PodConnect
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var assignmentsViewModel: AssignmentsViewModel
    @ObservedObject private var authService: AuthService
    @StateObject private var viewModel: CalendarViewModel
    @State private var selectedTab = 0
    @State private var showAddEvent = false
    @State private var selectedDate = Date()

    init(eventRepository: EventRepository, authService: AuthService) {
        self.authService = authService
        _viewModel = StateObject(wrappedValue: CalendarViewModel(eventRepository: eventRepository))
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                topHeader

                VStack(spacing: 0) {
                    Picker("", selection: $selectedTab) {
                        Text("Calendar").tag(0)
                        Text("Events").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    Divider()

                    if selectedTab == 0 {
                        CalendarTabView(
                            userEvents: viewModel.userEvents,
                            assignments: assignmentsViewModel.assignments,
                            selectedDate: $selectedDate,
                            selectedTab: $selectedTab,
                            onDeleteEvent: { event in
                                Task {
                                    await removeClassFromProfileIfNeeded(event)
                                    await viewModel.deleteEvent(event: event)
                                }
                            },
                            onDeleteSeries: { groupId in
                                Task {
                                    await removeClassSeriesFromProfileIfNeeded(groupId)
                                    await viewModel.deleteEventSeries(groupId: groupId)
                                }
                            },
                            onEditEvent: { updatedEvent in
                                Task {
                                    await viewModel.updateEvent(event: updatedEvent)
                                }
                            },
                            onEditSeries: { updatedEvent in
                                guard let groupId = updatedEvent.recurrenceGroupId else { return }
                                Task {
                                    await syncProfileClassNameIfNeeded(updatedEvent)
                                    await viewModel.updateEventSeries(groupId: groupId, template: updatedEvent)
                                }
                            }
                        )
                    } else {
                        EventsTabView(
                            userEvents: viewModel.userEvents,
                            selectedDate: $selectedDate,
                            selectedTab: $selectedTab,
                            onDeleteEvent: { event in
                                Task {
                                    await removeClassFromProfileIfNeeded(event)
                                    await viewModel.deleteEvent(event: event)
                                }
                            },
                            onDeleteSeries: { groupId in
                                Task {
                                    await removeClassSeriesFromProfileIfNeeded(groupId)
                                    await viewModel.deleteEventSeries(groupId: groupId)
                                }
                            },
                            onEditEvent: { updatedEvent in
                                Task {
                                    await viewModel.updateEvent(event: updatedEvent)
                                }
                            },
                            onEditSeries: { updatedEvent in
                                guard let groupId = updatedEvent.recurrenceGroupId else { return }
                                Task {
                                    await syncProfileClassNameIfNeeded(updatedEvent)
                                    await viewModel.updateEventSeries(groupId: groupId, template: updatedEvent)
                                }
                            }
                        )
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.fetchEvents()
            }
        }
        .sheet(isPresented: $showAddEvent) {
            AddEventSheet(initialDate: selectedDate) { events in
                Task {
                    await viewModel.saveEvents(events)
                    await viewModel.fetchEvents()

                    if let firstEventDate = events.first?.startDate {
                        selectedDate = firstEventDate
                    }

                    selectedTab = 0
                }
            }
        }
    }
    
    private func classTitle(_ title: String) -> String {
        title.components(separatedBy: "—").first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? title
    }

    private func updateProfileClasses(_ classes: [String]) async {
        guard let userInfo = authService.userInfo else { return }

        let updatedProfile = UserInfo(
            id: userInfo.id,
            username: userInfo.username,
            username_lowercase: userInfo.username_lowercase,
            name: userInfo.name,
            classes: classes,
            clubs: userInfo.clubs,
            friends: userInfo.friends,
            email: userInfo.email,
            uid: userInfo.uid,
            bio: userInfo.bio,
            profileImageURL: userInfo.profileImageURL,
            classesVisibility: userInfo.classesVisibility,
            clubsVisibility: userInfo.clubsVisibility
        )

        do {
            try await authService.updateUserProfile(updatedProfile)
        } catch {
            print("Failed to sync profile classes: \(error)")
        }
    }

    private func syncProfileClassNameIfNeeded(_ updatedEvent: UserEvent) async {
        guard updatedEvent.category == .academic else { return }
        guard let oldEvent = viewModel.userEvents.first(where: { $0.id == updatedEvent.id }) else { return }
        guard oldEvent.category == .academic else { return }

        let oldName = classTitle(oldEvent.title)
        let newName = classTitle(updatedEvent.title)

        guard oldName != newName else { return }
        guard var classes = authService.userInfo?.classes else { return }

        if let index = classes.firstIndex(of: oldName) {
            classes[index] = newName
        } else if !classes.contains(newName) {
            classes.append(newName)
        }

        await updateProfileClasses(classes)
    }

    private func removeClassFromProfileIfNeeded(_ event: UserEvent) async {
        guard event.category == .academic else { return }
        let name = classTitle(event.title)

        let remainingMatchingEvents = viewModel.userEvents.filter {
            $0.id != event.id &&
            $0.category == .academic &&
            classTitle($0.title) == name
        }

        guard remainingMatchingEvents.isEmpty else { return }
        guard var classes = authService.userInfo?.classes else { return }

        classes.removeAll { $0 == name }
        await updateProfileClasses(classes)
    }

    private func removeClassSeriesFromProfileIfNeeded(_ groupId: String) async {
        let seriesEvents = viewModel.userEvents.filter {
            $0.recurrenceGroupId == groupId &&
            $0.category == .academic
        }

        guard let first = seriesEvents.first else { return }

        let name = classTitle(first.title)

        let remainingMatchingEvents = viewModel.userEvents.filter {
            $0.recurrenceGroupId != groupId &&
            $0.category == .academic &&
            classTitle($0.title) == name
        }

        guard remainingMatchingEvents.isEmpty else { return }
        guard var classes = authService.userInfo?.classes else { return }

        classes.removeAll { $0 == name }
        await updateProfileClasses(classes)
    }
    

    private var topHeader: some View {
        HStack {
            Text("Calendar")
                .foregroundColor(.white)
                .font(.title)
                .fontWeight(.bold)

            Spacer()

            Button {
                showAddEvent = true
            } label: {
                Image(systemName: "plus")
                    .padding()
                    .glassEffect()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 18)
        .background(Color.islandsBlue)
    }
}

// MARK: - Calendar Tab
struct CalendarTabView: View {
    @EnvironmentObject var assignmentsViewModel: AssignmentsViewModel
    
    var userEvents: [UserEvent]
    var assignments: [CanvasAssignment]
    @Binding var selectedDate: Date
    @Binding var selectedTab: Int
    var onDeleteEvent: (UserEvent) -> Void
    var onDeleteSeries: (String) -> Void
    var onEditEvent: (UserEvent) -> Void
    var onEditSeries: (UserEvent) -> Void
    
    @State private var eventPendingDelete: UserEvent?
    @State private var eventToEdit: UserEvent?
    @State private var editScope: EditScope = .single
    @State private var showEditConfirmation = false
    @State private var showEditSheet = false

    private var schoolEventsOnDate: [SchoolEvent] {
        schoolEvents.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

   /*private var userEventsOnDate: [UserEvent] {
        userEvents
            .filter { Calendar.current.isDate($0.startDate, inSameDayAs: selectedDate) }
            .sorted { $0.startDate < $1.startDate }
    }*/
    
    private var userEventsOnDate: [UserEvent] {
        return userEvents
            .filter { Calendar.current.isDate($0.startDate, inSameDayAs: selectedDate) }
            .sorted { $0.startDate < $1.startDate }
    }

    private var classEventsOnDate: [UserEvent] {
        userEventsOnDate.filter { $0.category == .academic }
    }

    private var personalEventsOnDate: [UserEvent] {
        userEventsOnDate.filter { $0.category != .academic }
    }
    
    private var assignmentsOnDate: [CanvasAssignment] {
        assignments.filter {
            Calendar.current.isDate($0.dueDate, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        List {
            Section {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Color.islandsBlue)
                    .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if schoolEventsOnDate.isEmpty && classEventsOnDate.isEmpty && personalEventsOnDate.isEmpty && assignmentsOnDate.isEmpty {
                Section {
                    Text("No events on this day")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }

            if !classEventsOnDate.isEmpty {
                Section("Classes") {
                    ForEach(classEventsOnDate) { event in
                        UserEventRow(event: event)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if event.recurrenceGroupId != nil {
                                        eventPendingDelete = event
                                    } else {
                                        onDeleteEvent(event)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    eventToEdit = event
                                    if event.recurrenceGroupId != nil {
                                        showEditConfirmation = true
                                    } else {
                                        editScope = .single
                                        showEditSheet = true
                                    }
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(Color.islandsBlue)
                            }
                    }
                }
            }
            
            if !personalEventsOnDate.isEmpty {
                Section("My Events") {
                    ForEach(personalEventsOnDate) { event in
                        UserEventRow(event: event)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if event.recurrenceGroupId != nil {
                                        eventPendingDelete = event
                                    } else {
                                        onDeleteEvent(event)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    eventToEdit = event
                                    if event.recurrenceGroupId != nil {
                                        showEditConfirmation = true
                                    } else {
                                        editScope = .single
                                        showEditSheet = true
                                    }
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(Color.islandsBlue)
                            }
                    }
                }
            }
            
            if !assignmentsOnDate.isEmpty {
                Section("Assignments") {
                    ForEach(assignmentsOnDate) { assignment in
                        CanvasAssignmentRow(assignment: assignment)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await assignmentsViewModel.deleteAssignment(assignment)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    Task {
                                        await assignmentsViewModel.toggleCompleted(assignment)
                                    }
                                } label: {
                                    Label(
                                        assignment.isCompleted ? "Undo" : "Complete",
                                        systemImage: assignment.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                    )
                                }
                                .tint(Color.islandsBlue)
                            }
                    }
                }
            }

            if !schoolEventsOnDate.isEmpty {
                Section("Campus Events") {
                    ForEach(schoolEventsOnDate) { event in
                        SchoolEventRow(event: event)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .confirmationDialog("Delete Event", isPresented: Binding(
            get: { eventPendingDelete != nil },
            set: { if !$0 { eventPendingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete This Event", role: .destructive) {
                if let event = eventPendingDelete { onDeleteEvent(event) }
                eventPendingDelete = nil
            }
            Button("Delete All Events in Series", role: .destructive) {
                if let groupId = eventPendingDelete?.recurrenceGroupId { onDeleteSeries(groupId) }
                eventPendingDelete = nil
            }
            Button("Cancel", role: .cancel) { eventPendingDelete = nil }
        }
        .confirmationDialog("Edit Event", isPresented: $showEditConfirmation, titleVisibility: .visible) {
            Button("Edit This Event") {
                editScope = .single
                showEditSheet = true
            }
            Button("Edit All Events in Series") {
                editScope = .series
                showEditSheet = true
            }
            Button("Cancel", role: .cancel) { eventToEdit = nil }
        }
        .sheet(isPresented: $showEditSheet) {
            if let event = eventToEdit {
                EditEventSheet(event: event) { updated in
                    if editScope == .single { onEditEvent(updated) }
                    else { onEditSeries(updated) }
                    eventToEdit = nil
                }
            }
        }
    }
}

// MARK: - Events Tab
struct EventsTabView: View {
    var userEvents: [UserEvent]
    @Binding var selectedDate: Date
    @Binding var selectedTab: Int
    var onDeleteEvent: (UserEvent) -> Void
    var onDeleteSeries: (String) -> Void
    var onEditEvent: (UserEvent) -> Void
    var onEditSeries: (UserEvent) -> Void
    @State private var eventPendingDelete: UserEvent?
    @State private var eventToEdit: UserEvent?
    @State private var editScope: EditScope = .single
    @State private var showEditConfirmation = false
    @State private var showEditSheet = false
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var activeCategories: Set<String> = []

    private let allCategories = ["Academic", "Arts", "Campus Life", "Wellness", "Personal", "Work", "Other"]

    private var filteredSchoolEvents: [SchoolEvent] {
        let categoryFiltered: [SchoolEvent]

        if activeCategories.isEmpty {
            categoryFiltered = schoolEvents
        } else {
            categoryFiltered = schoolEvents.filter { activeCategories.contains($0.category) }
        }

        guard !searchText.isEmpty else { return categoryFiltered }

        return categoryFiltered.filter { event in
            event.title.localizedCaseInsensitiveContains(searchText) ||
            event.notes.localizedCaseInsensitiveContains(searchText) ||
            event.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredUserEvents: [UserEvent] {

        let categoryFiltered: [UserEvent]

        if activeCategories.isEmpty {
            categoryFiltered = userEvents
        } else {
            categoryFiltered = userEvents.filter { activeCategories.contains($0.category.rawValue) }
        }

        let today = Calendar.current.startOfDay(for: Date())
        let futureFiltered = categoryFiltered.filter { $0.startDate >= today }

        let searchFiltered: [UserEvent]

        if searchText.isEmpty {
            searchFiltered = futureFiltered
        } else {
            searchFiltered = futureFiltered.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.notes.localizedCaseInsensitiveContains(searchText) ||
                event.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }

        return searchFiltered.sorted { $0.startDate < $1.startDate }
    }

    private var groupedSchoolEvents: [(String, [SchoolEvent])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none

        let grouped = Dictionary(grouping: filteredSchoolEvents) {
            formatter.string(from: $0.date)
        }
        return grouped.sorted { a, b in
            let dateA = filteredSchoolEvents.first { formatter.string(from: $0.date) == a.0 }?.date ?? Date()
            let dateB = filteredSchoolEvents.first { formatter.string(from: $0.date) == b.0 }?.date ?? Date()
            return dateA < dateB
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    if !activeCategories.isEmpty {
                        Button(action: { activeCategories.removeAll() }) {
                            Text("Clear")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.15))
                                .foregroundColor(.red)
                                .clipShape(Capsule())
                        }
                    }

                    ForEach(allCategories, id: \.self) { category in
                        let isActive = activeCategories.contains(category)
                        Button(action: {
                            if isActive {
                                activeCategories.remove(category)
                            } else {
                                activeCategories.insert(category)
                            }
                        }) {
                            Text(category)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isActive ? categoryColor(category) : Color(.systemGray5))
                                .foregroundColor(isActive ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Divider()

            List {
                if !filteredUserEvents.isEmpty {
                    Section("My Events") {
                        ForEach(filteredUserEvents) { event in
                            Button {
                                selectedDate = event.startDate
                                selectedTab = 0
                            } label: {
                                UserEventRow(event: event)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if event.recurrenceGroupId != nil {
                                        eventPendingDelete = event
                                    } else {
                                        onDeleteEvent(event)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    eventToEdit = event
                                    if event.recurrenceGroupId != nil {
                                        showEditConfirmation = true
                                    } else {
                                        editScope = .single
                                        showEditSheet = true
                                    }
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(Color.islandsBlue)
                            }
                        }
                    }
                
                }
                
            

                ForEach(groupedSchoolEvents, id: \.0) { dateString, events in
                    Section(dateString) {
                        ForEach(events) { event in
                            Button {
                                selectedDate = event.date
                                selectedTab = 0
                            } label: {
                                SchoolEventRow(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if filteredUserEvents.isEmpty && groupedSchoolEvents.isEmpty {
                    Text("No matching events")
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.plain)
        }
        .searchable(
            text: $searchText,
            isPresented: $showSearch,
            prompt: "Search events"
        )
        .confirmationDialog("Delete Event", isPresented: Binding(
            get: { eventPendingDelete != nil },
            set: { if !$0 { eventPendingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete This Event", role: .destructive) {
                if let event = eventPendingDelete { onDeleteEvent(event) }
                eventPendingDelete = nil
            }
            Button("Delete All Events in Series", role: .destructive) {
                if let groupId = eventPendingDelete?.recurrenceGroupId { onDeleteSeries(groupId) }
                eventPendingDelete = nil
            }
            Button("Cancel", role: .cancel) { eventPendingDelete = nil }
        }
        .confirmationDialog("Edit Event", isPresented: $showEditConfirmation, titleVisibility: .visible) {
            Button("Edit This Event") {
                editScope = .single
                showEditSheet = true
            }
            Button("Edit All Events in Series") {
                editScope = .series
                showEditSheet = true
            }
            Button("Cancel", role: .cancel) { eventToEdit = nil }
        }
        .sheet(isPresented: $showEditSheet) {
            if let event = eventToEdit {
                EditEventSheet(event: event) { updated in
                    if editScope == .single { onEditEvent(updated) }
                    else { onEditSeries(updated) }
                    eventToEdit = nil
                }
            }
        }
    }

    func categoryColor(_ category: String) -> Color {
        switch category {
        case "Academic": return Color.islandsBlue
        case "Arts": return Color.channelClay
        case "Campus Life": return Color.islandsBlue
        case "Wellness": return Color.channelClay
        default: return .gray
        }
    }
}

// MARK: - Row Views
struct SchoolEventRow: View {
    let event: SchoolEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.body)

            HStack {
                Text(event.date, style: .time)
                    .font(.caption)
                    .foregroundColor(Color.islandsBlue)

                Text("·")
                    .foregroundColor(.secondary)

                Text(event.category)
                    .font(.caption)
                    .foregroundColor(categoryColor(event.category))
            }

            if !event.notes.isEmpty {
                Label(event.notes, systemImage: "mappin")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    func categoryColor(_ category: String) -> Color {
        switch category {
        case "Academic": return Color.islandsBlue
        case "Arts": return Color.channelClay
        case "Campus Life": return Color.islandsBlue
        case "Wellness": return Color.channelClay
        default: return .gray
        }
    }
}

struct UserEventRow: View {
    let event: UserEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(event.title)
                    .font(.body)
                if event.recurrenceGroupId != nil {
                    Image(systemName: "repeat")
                        .font(.caption)
                        .foregroundColor(Color.islandsBlue)
                }
            }
            HStack {
                Text(event.startDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(event.startDate, style: .time)
                Text("–")
                Text(event.endDate, style: .time)
            }
            .font(.caption)
            .foregroundColor(.gray)

            Text(event.category.rawValue)
                .font(.caption)
                .foregroundColor(Color.channelClay)

            if !event.notes.isEmpty {
                Text(event.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CanvasAssignmentRow: View {
    let assignment: CanvasAssignment

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(assignment.title)
                .font(.body)
                .strikethrough(assignment.isCompleted)
                .foregroundColor(assignment.isCompleted ? .secondary : .primary)

            Text(assignment.dueDate, style: .time)
                .font(.caption)
                .foregroundColor(assignment.isCompleted ? .secondary : Color.channelClay)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Shared helpers
enum EditScope { case single, series }

private let weekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]
// Calendar weekday values: 1=Sun 2=Mon 3=Tue 4=Wed 5=Thu 6=Fri 7=Sat

// MARK: - Add Event Sheet
struct AddEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    let initialDate: Date
    let onSave: ([UserEvent]) -> Void

    @State private var title = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes = ""
    @State private var category: EventCategory = .personal
    @State private var selectedWeekdays: Set<Int> = []
    @State private var recurrenceEndDate: Date

    init(initialDate: Date, onSave: @escaping ([UserEvent]) -> Void) {
        self.initialDate = initialDate
        self.onSave = onSave
        _startDate = State(initialValue: initialDate)
        _endDate = State(initialValue: initialDate.addingTimeInterval(3600))
        _recurrenceEndDate = State(initialValue: Calendar.current.date(byAdding: .month, value: 4, to: initialDate) ?? initialDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $title)
                    DatePicker("Start", selection: $startDate)
                    DatePicker("End", selection: $endDate)
                }
                Section("Repeat On") {
                    HStack(spacing: 6) {
                        ForEach(0..<7) { i in
                            let weekday = i + 1
                            let isSelected = selectedWeekdays.contains(weekday)
                            Button {
                                if isSelected { selectedWeekdays.remove(weekday) }
                                else { selectedWeekdays.insert(weekday) }
                            } label: {
                                Text(weekdayLabels[i])
                                    .font(.caption.bold())
                                    .frame(width: 34, height: 34)
                                    .background(isSelected ? Color.islandsBlue : Color(.systemGray5))
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

                    if !selectedWeekdays.isEmpty {
                        DatePicker("Until", selection: $recurrenceEndDate, in: startDate..., displayedComponents: .date)
                    }
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(EventCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Notes") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Color.islandsBlue)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.channelClay)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(buildEvents())
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .foregroundColor(title.isEmpty ? .gray : Color.islandsBlue)
                }
            }
        }
    }

    private func buildEvents() -> [UserEvent] {
        guard !selectedWeekdays.isEmpty else {
            return [UserEvent(title: title, startDate: startDate, endDate: endDate, notes: notes, category: category)]
        }

        let groupId = UUID().uuidString
        let duration = endDate.timeIntervalSince(startDate)
        let cal = Calendar.current
        var events: [UserEvent] = []
        var current = startDate

        while current <= recurrenceEndDate {
            let weekday = cal.component(.weekday, from: current)
            if selectedWeekdays.contains(weekday) {
                events.append(UserEvent(
                    title: title,
                    startDate: current,
                    endDate: current.addingTimeInterval(duration),
                    notes: notes,
                    category: category,
                    recurrenceGroupId: groupId
                ))
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return events
    }
}

// MARK: - Edit Event Sheet
struct EditEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    let event: UserEvent
    let onSave: (UserEvent) -> Void

    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes: String
    @State private var category: EventCategory

    init(event: UserEvent, onSave: @escaping (UserEvent) -> Void) {
        self.event = event
        self.onSave = onSave
        _title = State(initialValue: event.title)
        _startDate = State(initialValue: event.startDate)
        _endDate = State(initialValue: event.endDate)
        _notes = State(initialValue: event.notes)
        _category = State(initialValue: event.category)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $title)
                    DatePicker("Start", selection: $startDate)
                    DatePicker("End", selection: $endDate)
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(EventCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section("Notes") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Color.islandsBlue)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.channelClay)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = event
                        updated.title = title
                        updated.startDate = startDate
                        updated.endDate = endDate
                        updated.notes = notes
                        updated.category = category
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .foregroundColor(title.isEmpty ? .gray : Color.islandsBlue)
                }
            }
        }
    }
}

#Preview {
    let firestoreService = FirestoreService()
    let authService = AuthService(firestoreService: firestoreService)

    NavigationStack {
        CalendarView(
            eventRepository: EventRepository(
                firestoreService: firestoreService,
                authService: authService
            ),
            authService: authService
        )
        .environmentObject(AssignmentsViewModel())
    }
}
