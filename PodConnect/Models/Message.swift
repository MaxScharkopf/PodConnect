//
//  MessageModel.swift
//  PodConnect
//
//  Created by Noah Hester on 3/27/26.
//

import SwiftUI
import FirebaseFirestore

/*
 
 Firestore message thread collection structure:
 
 /messages/[messageThreadID]/messages/[messageID]
 
 As for documents, each message thread ID indexes a document that contains the name and participants in the message thread.
 The message ID documents contain the actual content of the message as wel as the sender ID and timestamp.
 
 */

struct MessageThread: Codable, Identifiable {
    @DocumentID var id: String?
    var participants: [String]
    var pendingParticipants: [String]
    var threadName: String
    var lastMessageAt: Date?
    var lastReadAt: [String: Date]?
    var ownerId: String

    init(id: String? = nil, participants: [String], pendingParticipants: [String], threadName: String, lastMessageAt: Date? = nil, lastReadAt: [String: Date]? = nil, ownerId: String) {
        self.id = id
        self.participants = participants
        self.pendingParticipants = pendingParticipants
        self.threadName = threadName
        self.lastMessageAt = lastMessageAt
        self.lastReadAt = lastReadAt
        self.ownerId = ownerId
    }
}

struct Message: Codable, Identifiable {
    @DocumentID var id: String?
    var content: String
    var sender: String
    var timestamp: Date
    var isEdited: Bool?
}
