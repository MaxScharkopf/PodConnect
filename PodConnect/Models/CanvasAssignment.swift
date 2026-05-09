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

    init(id: String, title: String, dueDate: Date, courseName: String?) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.courseName = courseName
    }
}
