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
    var threadName: String
    var lastMessageAt: Date?
    var lastReadAt: [String: Date]?
}

struct Message: Codable, Identifiable {
    @DocumentID var id: String?
    var content: String
    var sender: String
    var timestamp: Date
}
