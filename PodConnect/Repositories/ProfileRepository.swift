//
//  ProfileRepository.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 4/14/26.
//

import Foundation

final class ProfileRepository {
    private let firestoreService: FirestoreService
    private let usersPath = "users"
    
    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }
    
    func fetchUserProfile(uid: String) async throws -> UserInfo? {
        try await firestoreService.fetchDocument(path: usersPath, documentId: uid)
    }
    
    func createUserProfile(_ user: UserInfo) async throws {
        try await firestoreService.saveDocument(path: usersPath, documentId: user.uid, data: user)
    }
    
    func updateUserProfile(_ user: UserInfo) async throws {
        try await firestoreService.updateDocument(path: usersPath, documentId: user.uid, data: user)
    }
    
    func updateProfileImageURL(uid: String, profileImageURL: String) async throws {
        let partialUpdate = ["profileImageURL": profileImageURL]
        try await firestoreService.updateDocument(path: usersPath, documentId: uid, data: partialUpdate)
    }
}
