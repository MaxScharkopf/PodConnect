//
//  UserModel.swift
//  PodConnect
//
//  Created by Noah Hester on 3/27/26.
//
// Modified by: Kassidy Saffa
//

import FirebaseFirestore

enum VisibilityLevel: String, Codable, CaseIterable {
    case `public` = "Public"
    case friendsOnly = "Friends Only"
    case `private` = "Private"
}

struct UserInfo: Codable, Identifiable {
    @DocumentID var id: String?
    var username: String
    var username_lowercase: String
    var name: String
    var classes: [String]
    var clubs: [String]
    var friends: [String]
    var email: String
    var uid: String
    var bio: String
    var profileImageURL: String?

    var classesVisibility: VisibilityLevel
    var clubsVisibility: VisibilityLevel

    init(
        id: String? = nil,
        username: String,
        username_lowercase: String,
        name: String,
        classes: [String],
        clubs: [String],
        friends: [String] = [],
        email: String,
        uid: String,
        bio: String,
        profileImageURL: String? = nil,
        classesVisibility: VisibilityLevel = .public,
        clubsVisibility: VisibilityLevel = .public
    ) {
        self.id = id
        self.username = username
        self.username_lowercase = username_lowercase
        self.name = name
        self.classes = classes
        self.clubs = clubs
        self.email = email
        self.uid = uid
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.friends = friends
        self.classesVisibility = classesVisibility
        self.clubsVisibility = clubsVisibility
    }
}
