//
//  ToDoRepository.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 5/9/26.
//

import Foundation
import FirebaseFirestore

final class ToDoRepository {
    private let db = Firestore.firestore()
    private let uid: String

    init(uid: String) {
        self.uid = uid
    }

    func listenToTodos(completion: @escaping ([PodTask]) -> Void) {
        db.collection("todos")
            .whereField("ownerUid", isEqualTo: uid)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening to todos: \(error)")
                    return
                }

                let tasks = snapshot?.documents.compactMap { document -> PodTask? in
                    let data = document.data()

                    guard
                        let title = data["title"] as? String,
                        let isCompleted = data["isCompleted"] as? Bool,
                        let createdTimestamp = data["createdAt"] as? Timestamp,
                        let updatedTimestamp = data["updatedAt"] as? Timestamp
                    else {
                        return nil
                    }

                    return PodTask(
                        id: document.documentID,
                        title: title,
                        isCompleted: isCompleted,
                        createdAt: createdTimestamp.dateValue(),
                        updatedAt: updatedTimestamp.dateValue()
                    )
                } ?? []

                completion(tasks.sorted { $0.createdAt > $1.createdAt })
            }
    }

    func saveTask(_ task: PodTask) {
        let data: [String: Any] = [
            "id": task.id,
            "ownerUid": uid,
            "title": task.title,
            "isCompleted": task.isCompleted,
            "createdAt": Timestamp(date: task.createdAt),
            "updatedAt": Timestamp(date: task.updatedAt)
        ]

        db.collection("todos")
            .document(task.id)
            .setData(data) { error in
                if let error = error {
                    print("Error saving todo: \(error)")
                }
            }
    }

    func deleteTask(_ task: PodTask) {
        db.collection("todos")
            .document(task.id)
            .delete { error in
                if let error = error {
                    print("Error deleting todo: \(error)")
                }
            }
    }
}
