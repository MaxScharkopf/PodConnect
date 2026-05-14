//
//  ToDoViewModel.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 5/8/26.
//

import Foundation
import Combine

@MainActor
final class ToDoViewModel: ObservableObject {
    @Published var tasks: [PodTask] = []

    private let repository: ToDoRepository

    init(uid: String) {
        self.repository = ToDoRepository(uid: uid)
        listenToTodos()
    }

    private func listenToTodos() {
        repository.listenToTodos { [weak self] tasks in
            Task { @MainActor in
                self?.tasks = tasks
            }
        }
    }

    func addTask(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let task = PodTask(title: trimmed)
        repository.saveTask(task)
    }

    func toggleTask(_ task: PodTask) {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        updatedTask.updatedAt = Date()

        repository.saveTask(updatedTask)
    }

    func deleteTask(_ task: PodTask) {
        repository.deleteTask(task)
    }
}
