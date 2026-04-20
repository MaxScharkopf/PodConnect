//
//  UserModel.swift
//  PodConnect
//
//  Created by Noah Hester on 3/27/26.
//
// Modified by: Kassidy Saffa
//
// Simple user structure
import FirebaseAuth
import FirebaseFirestore

struct UserInfo: Codable, Identifiable {
    @DocumentID var id: String?
    var username: String
    var username_lowercase: String
    var classes: [String]
    var clubs: [String]
    var friends: [String]
    var email: String
    var uid: String
    var bio: String
    var profileImageURL: String?

    init(
        id: String? = nil,
        username: String,
        username_lowercase: String,
        classes: [String],
        clubs: [String],
        friends: [String] = [],
        email: String,
        uid: String,
        bio: String,
        profileImageURL: String? = nil
    ) {
        self.id = id
        self.username = username
        self.username_lowercase = username_lowercase
        self.classes = classes
        self.clubs = clubs
        self.email = email
        self.uid = uid
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.friends = friends
    }
}
