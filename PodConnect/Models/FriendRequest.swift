//
//  FriendRequest.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 4/6/26.
//

import Foundation
import FirebaseFirestore

struct FriendRequest: Codable, Identifiable {
    @DocumentID var id: String?
    var senderUid: String
    var receiverUid: String
    var status: String
    var timestamp: Timestamp
}
