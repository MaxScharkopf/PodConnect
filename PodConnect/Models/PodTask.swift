//
//  PodTask.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 5/8/26.
//

import Foundation

struct PodTask: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var isCompleted: Bool
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}
