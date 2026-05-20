//
//  PodTask.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 5/8/26.
//

import Foundation

struct PodTask: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
