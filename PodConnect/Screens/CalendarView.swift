//
//  CalendarView.swift
//  PodConnect
//

import SwiftUI

private let channelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)
private let islandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)

struct CalendarView: View {
    @StateObject private var viewModel: CalendarViewModel
    @State private var selectedTab = 0
    @State private var showAddEvent = false
    @State private var selectedDate = Date()

    init(eventRepository: EventRepository) {
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
                            selectedDate: $selectedDate,
                            selectedTab: $selectedTab,
                            onDeleteEvent: { event in Task { await viewModel.deleteEvent(event: event) } },
                            onDeleteSeries: { groupId in Task { await viewModel.deleteEventSeries(groupId: groupId) } }
                        )
                    } else {
                        EventsTabView(
                            userEvents: viewModel.userEvents,
                            selectedDate: $selectedDate,
                            selectedTab: $selectedTab,
                            onDeleteEvent: { event in Task { await viewModel.deleteEvent(event: event) } },
                            onDeleteSeries: { groupId in Task { await viewModel.deleteEventSeries(groupId: groupId) } }
                        )
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddEvent) {
            AddEventSheet(initialDate: selectedDate) { events in
                Task { await viewModel.saveEvents(events) }
            }
        }
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
        .background(islandsBlue)
    }
}

// MARK: - Calendar Tab
struct CalendarTabView: View {
    var userEvents: [UserEvent]
    @Binding var selectedDate: Date
    @Binding var selectedTab: Int
    var onDeleteEvent: (UserEvent) -> Void
    var onDeleteSeries: (String) -> Void

    @State private var eventPendingDelete: UserEvent?


    private var schoolEventsOnDate: [SchoolEvent] {
        schoolEvents.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var userEventsOnDate: [UserEvent] {
        userEvents.filter { Calendar.current.isDate($0.startDate, inSameDayAs: selectedDate) }
    }

    var body: some View {
        VStack(spacing: 0) {
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding(.horizontal)
                .tint(islandsBlue)

            Divider()

            if schoolEventsOnDate.isEmpty && userEventsOnDate.isEmpty {
                Spacer()
                Text("No events on this day")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List {
                    if !userEventsOnDate.isEmpty {
                        Section("My Events") {
                            ForEach(userEventsOnDate) { event in
                                UserEventRow(event: event)
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { i in
                                    let event = userEventsOnDate[i]
                                    if event.recurrenceGroupId != nil {
                                        eventPendingDelete = event
                                    } else {
                                        onDeleteEvent(event)
                                    }
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
                .listStyle(.plain)
            }
        }
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
    }
}

// MARK: - Events Tab
struct EventsTabView: View {
    var userEvents: [UserEvent]
    @Binding var selectedDate: Date
    @Binding var selectedTab: Int
    var onDeleteEvent: (UserEvent) -> Void
    var onDeleteSeries: (String) -> Void
    @State private var eventPendingDelete: UserEvent?
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

        guard !searchText.isEmpty else { return categoryFiltered }

        return categoryFiltered.filter { event in
            event.title.localizedCaseInsensitiveContains(searchText) ||
            event.notes.localizedCaseInsensitiveContains(searchText) ||
            event.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
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
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { i in
                                let event = filteredUserEvents[i]
                                if event.recurrenceGroupId != nil {
                                    eventPendingDelete = event
                                } else {
                                    onDeleteEvent(event)
                                }
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
    }

    func categoryColor(_ category: String) -> Color {
        switch category {
        case "Academic": return islandsBlue
        case "Arts": return channelClay
        case "Campus Life": return islandsBlue
        case "Wellness": return channelClay
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
                    .foregroundColor(islandsBlue)

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
        case "Academic": return islandsBlue
        case "Arts": return channelClay
        case "Campus Life": return islandsBlue
        case "Wellness": return channelClay
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
                        .foregroundColor(islandsBlue)
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
                .foregroundColor(channelClay)

            if !event.notes.isEmpty {
                Text(event.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

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
    @State private var isRecurring = false
    @State private var recurrenceEndDate: Date

    init(initialDate: Date, onSave: @escaping ([UserEvent]) -> Void) {
        self.initialDate = initialDate
        self.onSave = onSave
        _startDate = State(initialValue: initialDate)
        _endDate = State(initialValue: initialDate.addingTimeInterval(3600))
        // Default series end to ~4 months out (a typical semester)
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
                Section("Recurrence") {
                    Toggle("Repeat Weekly", isOn: $isRecurring)
                    if isRecurring {
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
            .tint(islandsBlue)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(channelClay)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(buildEvents())
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .foregroundColor(title.isEmpty ? .gray : islandsBlue)
                }
            }
        }
    }

    private func buildEvents() -> [UserEvent] {
        guard isRecurring else {
            return [UserEvent(title: title, startDate: startDate, endDate: endDate, notes: notes, category: category)]
        }

        let groupId = UUID().uuidString
        let duration = endDate.timeIntervalSince(startDate)
        var events: [UserEvent] = []
        var current = startDate

        while current <= recurrenceEndDate {
            events.append(UserEvent(
                title: title,
                startDate: current,
                endDate: current.addingTimeInterval(duration),
                notes: notes,
                category: category,
                recurrenceGroupId: groupId
            ))
            guard let next = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: current) else { break }
            current = next
        }

        return events
    }
}

#Preview {
    NavigationStack {
        CalendarView(
            eventRepository: EventRepository(
                firestoreService: FirestoreService(),
                authService: AuthService(firestoreService: FirestoreService())
            )
        )
    }
}
