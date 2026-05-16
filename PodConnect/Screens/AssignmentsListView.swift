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

    
    

    private var visibleAssignments: [CanvasAssignment] {
        switch selectedRange {
        case .today: return viewModel.todaysAssignments
        case .sevenDays: return viewModel.next7DaysAssignments
        case .thirtyDays: return viewModel.next30DaysAssignments
        }
    }
    
    private func dueDateText(for assignment: CanvasAssignment) -> String {
        if selectedRange == .today {
            return assignment.dueDate.formatted(.dateTime.hour().minute())
        } else {
            return assignment.dueDate.formatted(.dateTime.month(.abbreviated).day().hour().minute())
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
                            HStack(spacing: 10) {
                                Button {
                                    Task { await viewModel.toggleCompleted(assignment) }
                                } label: {
                                    Image(systemName: assignment.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(Color.channelClay)
                                }
                                .buttonStyle(.plain)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(assignment.title)
                                        .font(.body)
                                        .lineLimit(2)
                                        .strikethrough(assignment.isCompleted)
                                        .foregroundColor(assignment.isCompleted ? .secondary : .primary)

                                    Text(dueDateText(for: assignment))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteAssignment(assignment) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
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
                .foregroundColor(Color.islandsBlue.opacity(0.7))

            Text("No assignments")
                .font(.headline)
                .foregroundColor(Color.islandsBlue)

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
    case sevenDays
    case thirtyDays
    
    var title: String {
        switch self {
        case .today: return "Today"
        case .sevenDays: return "7 Days"
        case .thirtyDays: return "30 Days"
        }
    }
}


