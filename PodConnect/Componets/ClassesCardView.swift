//
//  ClassesCardView.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 5/11/26.
//

import Foundation
import SwiftUI

struct ClassesCardView: View {
    @Binding var selectedTab: Int
    var userEvents: [UserEvent] = []

    private let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)
    private let ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)

    private var todaysClasses: [UserEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()

        return userEvents
            .filter { event in
                event.category == .academic &&
                event.endDate >= Date() && //can remove event.endDate >= Date() form conditional if want home to show classes that already passed today
                event.startDate >= today &&
                event.startDate < tomorrow
            }
            .sorted { $0.startDate < $1.startDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundColor(IslandsBlue)

                Text("Classes")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(IslandsBlue)

                Spacer()

                Button {
                    selectedTab = 3
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(IslandsBlue)
                }
            }

            Divider()

            if todaysClasses.isEmpty {
                Text("No classes today")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(todaysClasses.prefix(3)) { event in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(colorForClass(event))
                            .frame(width: 5, height: 42)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(classTitle(event.title))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)

                            Text(classLocation(event.title))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text(classTime(event))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func classTitle(_ title: String) -> String {
        title.components(separatedBy: "—").first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? title
    }

    private func classLocation(_ title: String) -> String {
        let parts = title.components(separatedBy: "—")
        return parts.count > 1
            ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            : "No location"
    }

    private func classTime(_ event: UserEvent) -> String {
        "\(event.startDate.formatted(.dateTime.hour().minute())) – \(event.endDate.formatted(.dateTime.hour().minute()))"
    }

    private func colorForClass(_ event: UserEvent) -> Color {
        let colors: [Color] = [.green, IslandsBlue, ChannelClay, .blue, .purple]
        let index = abs(event.title.hashValue) % colors.count
        return colors[index]
    }
}
