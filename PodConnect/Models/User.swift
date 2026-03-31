//
//  UserModel.swift
//  PodConnect
//
//  Created by Noah Hester on 3/27/26.
//

// Simple user structure
import FirebaseAuth
import FirebaseFirestore

// Database user data structure
struct UserInfo: Codable, Identifiable {
    @DocumentID var id: String?
    var username: String
    var classes: [String]
    var clubs: [String]
    var email: String
    var uid: String
    var bio: String
}
