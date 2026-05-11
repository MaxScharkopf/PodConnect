//
//  AddClassView.swift
//  PodConnect
//

import SwiftUI

struct AddClassView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: ([UserEvent]) -> Void

    @State private var className = ""
    @State private var room = ""
    @State private var selectedWeekdays: Set<Int> = []
    @State private var startTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var endTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var semesterEnd = Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date()

    private let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)
    private let ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)
    private let weekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    private var canSave: Bool {
        !className.trimmingCharacters(in: .whitespaces).isEmpty && !selectedWeekdays.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Class Info") {
                    TextField("Class Name (e.g. Biology 101)", text: $className)
                    TextField("Room (e.g. Del Norte 1500)", text: $room)
                }

                Section("Meeting Times") {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }

                Section("Days of the Week") {
                    HStack(spacing: 8) {
                        ForEach(0..<7) { i in
                            let weekday = i + 1
                            let isSelected = selectedWeekdays.contains(weekday)
                            Button {
                                if isSelected { selectedWeekdays.remove(weekday) }
                                else { selectedWeekdays.insert(weekday) }
                            } label: {
                                Text(weekdayLabels[i])
                                    .font(.caption.bold())
                                    .frame(width: 36, height: 36)
                                    .background(isSelected ? IslandsBlue : Color(.systemGray5))
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }

                Section("Semester End Date") {
                    DatePicker("Until", selection: $semesterEnd, in: Date()..., displayedComponents: .date)
                }
            }
            .navigationTitle("Add Class")
            .navigationBarTitleDisplayMode(.inline)
            .tint(IslandsBlue)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(ChannelClay)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(buildEvents())
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }

    private func buildEvents() -> [UserEvent] {
        let cal = Calendar.current
        let groupId = UUID().uuidString
        let title = room.trimmingCharacters(in: .whitespaces).isEmpty
            ? className
            : "\(className) — \(room)"
        let startComponents = cal.dateComponents([.hour, .minute], from: startTime)
        let endComponents = cal.dateComponents([.hour, .minute], from: endTime)

        var events: [UserEvent] = []
        var cursor = Date()

        while cursor <= semesterEnd {
            let weekday = cal.component(.weekday, from: cursor)
            if selectedWeekdays.contains(weekday),
               let start = cal.date(bySettingHour: startComponents.hour ?? 9,
                                    minute: startComponents.minute ?? 0,
                                    second: 0, of: cursor),
               let end = cal.date(bySettingHour: endComponents.hour ?? 10,
                                  minute: endComponents.minute ?? 0,
                                  second: 0, of: cursor) {
                events.append(UserEvent(
                    title: title,
                    startDate: start,
                    endDate: end,
                    notes: "",
                    category: .academic,
                    recurrenceGroupId: groupId
                ))
            }
            cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? cursor.addingTimeInterval(86400)
        }

        return events
    }
}
