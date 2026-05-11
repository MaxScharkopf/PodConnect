//
//  AssignmentsViewModel.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 5/9/26.
//

import Foundation
import Combine

@MainActor
final class AssignmentsViewModel: ObservableObject {
    @Published var assignments: [CanvasAssignment] = []
    @Published var canvasURL: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false

    private let service = CanvasICalService()
    private let repository = AssignmentRepository()

    init() {
        repository.listenToAssignments { [weak self] assignments in
            Task { @MainActor in
                self?.assignments = assignments.sorted { $0.dueDate < $1.dueDate }
            }
        }

        Task {
            await loadSavedCanvasURL()
        }
    }


    var todaysAssignments: [CanvasAssignment] {
        assignments.filter {
            Calendar.current.isDateInToday($0.dueDate)
        }
    }

    var activeTodaysAssignments: [CanvasAssignment] {
        todaysAssignments.filter {
            !$0.isCompleted
        }
    }
    
    
    var next7DaysAssignments: [CanvasAssignment] {
        upcomingAssignments(days: 7)
    }

    var next30DaysAssignments: [CanvasAssignment] {
        upcomingAssignments(days: 30)
    }

    private func upcomingAssignments(days: Int) -> [CanvasAssignment] {
        let start = Calendar.current.startOfDay(for: Date())

        guard let rawEnd = Calendar.current.date(byAdding: .day, value: days, to: start),
              let end = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: rawEnd)
        else {
            return []
        }

        return assignments.filter {
            $0.dueDate >= start &&
            $0.dueDate <= end
        }
    }

    func toggleCompleted(_ assignment: CanvasAssignment) async {
        do {
            try await repository.updateAssignmentCompletion(
                assignment,
                isCompleted: !assignment.isCompleted
            )
        } catch {
            errorMessage = "Could not update assignment."
            print("Failed to update assignment:", error)
        }
    }

    func deleteAssignment(_ assignment: CanvasAssignment) async {
        do {
            try await repository.deleteAssignment(assignment)
        } catch {
            errorMessage = "Could not delete assignment."
            print("Failed to delete assignment:", error)
        }
    }

    func loadSavedCanvasURL() async {
        do {
            canvasURL = try await repository.fetchCanvasURL()
        } catch {
            print("Failed to fetch Canvas URL:", error)
        }
    }

    func loadAssignments() async {
        errorMessage = ""
        isLoading = true

        do {
            let result = try await service.fetchAssignments(from: canvasURL)
            let sorted = result.sorted { $0.dueDate < $1.dueDate }

            try await repository.saveCanvasURL(canvasURL)
            try await repository.saveAssignments(sorted)

            if sorted.isEmpty {
                errorMessage = "No assignments found. Check your Canvas calendar feed link."
            }
        } catch {
            errorMessage = "Could not import. Make sure you pasted the full Canvas calendar feed link."
            print("Failed to load assignments:", error)
        }

        isLoading = false
    }
}
