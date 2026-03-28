//
//  MessageModel.swift
//  PodConnect
//
//  Created by Noah Hester on 3/27/26.
//

import SwiftUI
import FirebaseFirestore

struct MessageThread: Codable, Identifiable {
    @DocumentID var id: String?
    var participants: [String]
    var threadName: String
}

struct Message: Codable, Identifiable {
    @DocumentID var id: String?
    var content: String
    var sender: String
    var timestamp: Date
}
