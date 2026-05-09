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
    
    var weekAssignments: [CanvasAssignment] {
        guard let week = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else {
            return []
        }

        return assignments.filter {
            week.contains($0.dueDate)
        }
    }

    var monthAssignments: [CanvasAssignment] {
        guard let month = Calendar.current.dateInterval(of: .month, for: Date()) else {
            return []
        }

        return assignments.filter {
            month.contains($0.dueDate)
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
