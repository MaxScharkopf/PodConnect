//
//  CalendarView.swift
//  PodConnect
//

import SwiftUI

struct CalendarView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Sub-tab picker
            Picker("", selection: $selectedTab) {
                Text("Calendar").tag(0)
                Text("Events").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            if selectedTab == 0 {
                CalendarTabView()
            } else {
                EventsTabView()
            }
        }
        .navigationTitle("Calendar")
    }
}

// MARK: - Calendar Tab (Mockup)
struct CalendarTabView: View {
    @State private var selectedDate = Date()

    var body: some View {
        VStack {
            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()

            Divider()

            // Placeholder for events on selected day
            VStack(alignment: .leading, spacing: 12) {
                Text("Events on this day")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)

                List {
                    Text("No events")
                        .foregroundColor(.secondary)
                }
                .listStyle(.plain)
            }

            Spacer()
        }
    }
}

// MARK: - Events Tab (Mockup)
struct EventsTabView: View {
    var body: some View {
        List {
            Section("Upcoming") {
                EventRowMockup(title: "Club Fair", date: "Apr 2 · 10:00 AM", location: "Bell Tower")
                EventRowMockup(title: "Study Group", date: "Apr 3 · 2:00 PM", location: "Library")
            }
            Section("This Week") {
                EventRowMockup(title: "Guest Lecture", date: "Apr 5 · 5:00 PM", location: "Broome Library")
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct EventRowMockup: View {
    let title: String
    let date: String
    let location: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.body)
            Text(date)
                .font(.caption)
                .foregroundColor(.secondary)
            Label(location, systemImage: "mappin")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        CalendarView()
    }
}
