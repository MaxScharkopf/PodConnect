//
//  CanvasAssignment.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 5/9/26.
//

import Foundation

struct CanvasAssignment: Identifiable, Codable {
    let id: String
    let title: String
    let dueDate: Date
    let courseName: String?
    var isCompleted: Bool

    init(id: String, title: String, dueDate: Date, courseName: String?, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.courseName = courseName
        self.isCompleted = isCompleted
    }
}
