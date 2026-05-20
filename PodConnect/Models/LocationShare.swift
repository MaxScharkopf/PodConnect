//
//  LocationShare.swift
//  PodConnect
//
//  Created by Jacob Russell on 5/12/26.
//

import Foundation
import FirebaseFirestore

struct LiveLocationShare: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerUid: String
    var ownerUsername: String
    var receiverUid: String
    var latitude: Double
    var longitude: Double
    var isActive: Bool
    var updatedAt: Timestamp
}
