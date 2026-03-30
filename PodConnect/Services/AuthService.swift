//
//  AuthService.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 3/28/26.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

final class AuthService: ObservableObject {
    @Published var currentUser: User?

    private let db = Firestore.firestore()

    // Creates a new Firebase Auth user and corresponding Firestore profile.
    func signUp(email: String, password: String, username: String?) async throws {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanUsername = username?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let cleanUsername, !cleanUsername.isEmpty {
            let usernameSnapshot = try await db.collection("users")
                .whereField("username_lowercase", isEqualTo: cleanUsername.lowercased())
                .limit(to: 1)
                .getDocuments()

            if !usernameSnapshot.documents.isEmpty {
                throw AuthError.usernameAlreadyTaken
            }
        }

        do {
            let result = try await Auth.auth().createUser(
                withEmail: cleanEmail,
                password: password
            )
            let user = result.user
            currentUser = user

            let profile = UserInfo(
                id: user.uid,
                username: cleanUsername ?? "",
                classes: [],
                clubs: [],
                email: cleanEmail,
                uid: user.uid,
                bio: ""
            )

            try await db.collection("users")
                .document(user.uid)
                .setData([
                    "uid": profile.uid,
                    "email": profile.email,
                    "username": profile.username,
                    "username_lowercase": profile.username.lowercased(),
                    "bio": profile.bio,
                    "clubs": profile.clubs,
                    "classes": profile.classes,
                    "profileImageURL": ""
                ])

        } catch {
            let nsError = error as NSError

            if nsError.domain == AuthErrorDomain,
               let code = AuthErrorCode(rawValue: nsError.code) {
                switch code {
                case .emailAlreadyInUse:
                    throw AuthError.emailAlreadyInUse
                case .invalidEmail:
                    throw AuthError.invalidEmail
                default:
                    throw AuthError.generic
                }
            }

            throw AuthError.generic
        }
    }

    // Signs in using either email or username.
    func signIn(identifier: String, password: String) async throws {
        let cleanIdentifier = identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if cleanIdentifier.contains("@") {
            let emailSnapshot = try await db.collection("users")
                .whereField("email", isEqualTo: cleanIdentifier)
                .limit(to: 1)
                .getDocuments()

            guard !emailSnapshot.documents.isEmpty else {
                throw AuthError.emailNotFound
            }

            do {
                let result = try await Auth.auth().signIn(
                    withEmail: cleanIdentifier,
                    password: password
                )
                currentUser = result.user
            } catch {
                let nsError = error as NSError

                if nsError.domain == AuthErrorDomain,
                   let code = AuthErrorCode(rawValue: nsError.code) {
                    switch code {
                    case .wrongPassword,
                         .invalidCredential,
                         .userNotFound,
                         .invalidEmail:
                        throw AuthError.incorrectPassword
                    default:
                        throw AuthError.generic
                    }
                }

                throw AuthError.generic
            }

            return
        }

        let usernameSnapshot = try await db.collection("users")
            .whereField("username_lowercase", isEqualTo: cleanIdentifier)
            .limit(to: 1)
            .getDocuments()

        guard let document = usernameSnapshot.documents.first,
              let email = document.data()["email"] as? String else {
            throw AuthError.usernameNotFound
        }

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            currentUser = result.user
        } catch {
            let nsError = error as NSError

            if nsError.domain == AuthErrorDomain,
               let code = AuthErrorCode(rawValue: nsError.code) {
                switch code {
                case .wrongPassword,
                     .invalidCredential,
                     .userNotFound,
                     .invalidEmail:
                    throw AuthError.incorrectPassword
                default:
                    throw AuthError.generic
                }
            }

            throw AuthError.generic
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
    }

    func currentAuthenticatedUser() -> User? {
        Auth.auth().currentUser
    }

    // Loads the signed-in user's Firestore profile.
    func fetchUserProfile() async throws -> UserInfo {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthError.generic
        }

        let snapshot = try await db.collection("users").document(uid).getDocument()

        guard let data = snapshot.data() else {
            throw AuthError.generic
        }

        return UserInfo(
            id: snapshot.documentID,
            username: data["username"] as? String ?? "",
            classes: data["classes"] as? [String] ?? [],
            clubs: data["clubs"] as? [String] ?? [],
            email: data["email"] as? String ?? "",
            uid: data["uid"] as? String ?? uid,
            bio: data["bio"] as? String ?? ""
        )
    }

    // Saves profile changes while preserving case-insensitive username lookup.
    func updateUserProfile(_ profile: UserInfo) async throws {
        let trimmedUsername = profile.username.trimmingCharacters(in: .whitespacesAndNewlines)

        let snapshot = try await db.collection("users")
            .whereField("username_lowercase", isEqualTo: trimmedUsername.lowercased())
            .getDocuments()

        let isTaken = snapshot.documents.contains { $0.documentID != profile.uid }

        if isTaken {
            throw AuthError.usernameAlreadyTaken
        }

        try await db.collection("users").document(profile.uid).updateData([
            "username": trimmedUsername,
            "username_lowercase": trimmedUsername.lowercased(),
            "bio": profile.bio,
            "clubs": profile.clubs,
            "classes": profile.classes
        ])
    }
}

enum AuthError: LocalizedError {
    case emailAlreadyInUse
    case usernameAlreadyTaken
    case usernameNotFound
    case emailNotFound
    case incorrectPassword
    case invalidEmail
    case generic

    var errorDescription: String? {
        switch self {
        case .emailAlreadyInUse:
            return "That email is already associated with an account."
        case .usernameAlreadyTaken:
            return "That username is already taken."
        case .usernameNotFound:
            return "Email/username not found."
        case .emailNotFound:
            return "Email/username not found."
        case .incorrectPassword:
            return "Incorrect password."
        case .invalidEmail:
            return "Please enter a valid email."
        case .generic:
            return "Something went wrong. Please try again."
        }
    }
}
