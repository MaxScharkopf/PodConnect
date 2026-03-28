//
//  UserModel.swift
//  PodConnect
//
//  Created by Noah Hester on 3/27/26.
//

// Simple user structure
import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    var username: String
    var friends: [String]
}
