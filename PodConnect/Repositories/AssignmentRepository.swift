//
//  AssignmentRepository.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 5/9/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AssignmentRepository {
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private var currentUid: String? {
        Auth.auth().currentUser?.uid
    }

    func listenToAssignments(_ onChange: @escaping ([CanvasAssignment]) -> Void) {
        guard let uid = currentUid else {
            onChange([])
            return
        }

        listener?.remove()

        listener = db
            .collection("users")
            .document(uid)
            .collection("assignments")
            .order(by: "dueDate")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Assignment listener error:", error)
                    onChange([])
                    return
                }

                let assignments: [CanvasAssignment] = snapshot?.documents.compactMap { doc -> CanvasAssignment? in
                    let data = doc.data()

                    guard
                        let title = data["title"] as? String,
                        let timestamp = data["dueDate"] as? Timestamp
                    else {
                        return nil
                    }

                    return CanvasAssignment(
                        id: data["canvasUID"] as? String ?? doc.documentID,
                        title: title,
                        dueDate: timestamp.dateValue(),
                        courseName: data["courseName"] as? String,
                        isCompleted: data["isCompleted"] as? Bool ?? false
                    )
                } ?? []

                onChange(assignments)
            }
    }

    func saveAssignments(_ assignments: [CanvasAssignment]) async throws {
        guard let uid = currentUid else { return }

        let collection = db
            .collection("users")
            .document(uid)
            .collection("assignments")

        for assignment in assignments {
            let docId = safeDocumentID(from: assignment.id)

            try await collection.document(docId).setData([
                "canvasUID": assignment.id,
                "title": assignment.title,
                "dueDate": Timestamp(date: assignment.dueDate),
                "courseName": assignment.courseName as Any,
                "updatedAt": FieldValue.serverTimestamp(),
                "isCompleted": assignment.isCompleted
            ], merge: true)
        }
    }

    func saveCanvasURL(_ url: String) async throws {
        guard let uid = currentUid else { return }

        try await db
            .collection("users")
            .document(uid)
            .collection("settings")
            .document("canvas")
            .setData([
                "calendarFeedURL": url,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }

    func fetchCanvasURL() async throws -> String {
        guard let uid = currentUid else { return "" }

        let snapshot = try await db
            .collection("users")
            .document(uid)
            .collection("settings")
            .document("canvas")
            .getDocument()

        return snapshot.data()?["calendarFeedURL"] as? String ?? ""
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func deleteAssignment(_ assignment: CanvasAssignment) async throws {
        guard let uid = currentUid else { return }

        let docId = safeDocumentID(from: assignment.id)

        try await db
            .collection("users")
            .document(uid)
            .collection("assignments")
            .document(docId)
            .delete()
    }

    func updateAssignmentCompletion(_ assignment: CanvasAssignment, isCompleted: Bool) async throws {
        guard let uid = currentUid else { return }

        let docId = safeDocumentID(from: assignment.id)

        try await db
            .collection("users")
            .document(uid)
            .collection("assignments")
            .document(docId)
            .setData([
                "isCompleted": isCompleted,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }

    private func safeDocumentID(from string: String) -> String {
        string
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: "#", with: "_")
            .replacingOccurrences(of: "?", with: "_")
    }
    
}
