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

    private let storageKey = "podconnect.todo.tasks"

    init() {
        loadTasks()
    }

    func addTask(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        tasks.insert(PodTask(title: trimmed), at: 0)
        saveTasks()
    }

    func toggleTask(_ task: PodTask) {
        guard let index = tasks.firstIndex(of: task) else { return }
        tasks[index].isCompleted.toggle()
        saveTasks()
    }

    func deleteTask(_ task: PodTask) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    private func loadTasks() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }

        do {
            tasks = try JSONDecoder().decode([PodTask].self, from: data)
        } catch {
            tasks = []
        }
    }

    private func saveTasks() {
        do {
            let data = try JSONEncoder().encode(tasks)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save tasks: \(error)")
        }
    }
}
