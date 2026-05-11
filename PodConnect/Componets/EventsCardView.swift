//
//  EventsCardView.swift
//  PodConnect
//

import SwiftUI

struct EventsCardView: View {
    @Binding var selectedTab: Int
    var userEvents: [UserEvent] = []

    private let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)

    private struct EventRow: Identifiable {
        let id = UUID()
        let title: String
        let startTime: Date
        let endTime: Date?
        let icon: String
    }

    private var todayRows: [EventRow] {
        let today = Calendar.current.startOfDay(for: Date())
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else { return [] }

        let now = Date()

        let school = schoolEvents
            .filter { $0.date >= now && $0.date < tomorrow }
            .map { EventRow(title: $0.title, startTime: $0.date, endTime: $0.date.addingTimeInterval($0.duration), icon: schoolIcon(for: $0.category)) }

        let personal = userEvents
            .filter { $0.startDate >= now && $0.startDate < tomorrow }
            .map { EventRow(title: $0.title, startTime: $0.startDate, endTime: $0.endDate, icon: userIcon(for: $0.category)) }

        return Array((personal + school).sorted { $0.startTime < $1.startTime }.prefix(3))
    }

    private func schoolIcon(for category: String) -> String {
        switch category {
        case "Campus Life": return "person.3.fill"
        case "Academic":    return "info.circle.fill"
        case "Arts":        return "star.fill"
        case "Wellness":    return "heart.fill"
        default:            return "calendar"
        }
    }

    private func userIcon(for category: EventCategory) -> String {
        switch category {
        case .academic:   return "book.fill"
        case .arts:       return "star.fill"
        case .campusLife: return "person.3.fill"
        case .wellness:   return "heart.fill"
        case .work:       return "briefcase.fill"
        case .personal:   return "person.fill"
        case .other:      return "calendar"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(IslandsBlue)
                Text("Events")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    selectedTab = 3
                } label: {
                    Text("Today")
                        .font(.subheadline)
                        .foregroundColor(IslandsBlue)
                }
            }

            Divider()

            if todayRows.isEmpty {
                Text("No events today")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(todayRows) { row in
                    HStack(spacing: 12) {
                        Image(systemName: row.icon)
                            .foregroundColor(IslandsBlue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(row.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            if let end = row.endTime {
                                Text("\(row.startTime.formatted(.dateTime.hour().minute())) – \(end.formatted(.dateTime.hour().minute()))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text(row.startTime.formatted(.dateTime.hour().minute()))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 3)
    }
}
