//
//  AssignmentsListView.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 5/9/26.
//

import Foundation
import SwiftUI

struct AssignmentsListView: View {
    @EnvironmentObject var viewModel: AssignmentsViewModel
    @State private var selectedRange: AssignmentRange = .today

    private let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)
    private let ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)

    private var visibleAssignments: [CanvasAssignment] {
        switch selectedRange {
        case .today:
            return viewModel.todaysAssignments
        case .week:
            return viewModel.weekAssignments
        case .month:
            return viewModel.monthAssignments
        }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Picker("", selection: $selectedRange) {
                    ForEach(AssignmentRange.allCases, id: \.self) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if visibleAssignments.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(visibleAssignments) { assignment in
                            AssignmentListRow(assignment: assignment)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle("Assignments")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "checkmark.circle")
                .font(.system(size: 42))
                .foregroundColor(IslandsBlue.opacity(0.7))

            Text("No assignments")
                .font(.headline)
                .foregroundColor(IslandsBlue)

            Text("Nothing due for this \(selectedRange.title.lowercased()).")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }
}

private enum AssignmentRange: CaseIterable {
    case today
    case week
    case month

    var title: String {
        switch self {
        case .today: return "Today"
        case .week: return "Week"
        case .month: return "Month"
        }
    }
}

private struct AssignmentListRow: View {
    let assignment: CanvasAssignment

    private let ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(assignment.title)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(2)

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.caption)

                Text(assignment.dueDate, style: .date)
                Text("at")
                Text(assignment.dueDate, style: .time)
            }
            .font(.caption)
            .foregroundColor(ChannelClay)
        }
        .padding(.vertical, 5)
    }
}
