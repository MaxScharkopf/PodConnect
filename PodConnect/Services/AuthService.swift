//
//  AuthService.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 3/28/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthService {
    private let db = Firestore.firestore()

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

            var data: [String: Any] = [
                "uid": user.uid,
                "email": cleanEmail,
                "bio": "",
                "clubs": [],
                "classes": [],
                "profileImageURL": ""
            ]

            if let cleanUsername, !cleanUsername.isEmpty {
                data["username"] = cleanUsername
                data["username_lowercase"] = cleanUsername.lowercased()
            } else {
                data["username"] = ""
                data["username_lowercase"] = ""
            }

            try await db.collection("users")
                .document(user.uid)
                .setData(data)

        } catch {
            let nsError = error as NSError

            if nsError.domain == AuthErrorDomain,
               let code = AuthErrorCode(rawValue: nsError.code) {
                switch code {
                case .emailAlreadyInUse:
                    throw AuthError.emailAlreadyInUse
                default:
                    throw AuthError.generic
                }
            }

            throw AuthError.generic
        }
    }
    
    func signIn(identifier: String, password: String) async throws {
        let cleanIdentifier = identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // EMAIL LOGIN
        if cleanIdentifier.contains("@") {
            let emailSnapshot = try await db.collection("users")
                .whereField("email", isEqualTo: cleanIdentifier)
                .limit(to: 1)
                .getDocuments()

            guard !emailSnapshot.documents.isEmpty else {
                throw AuthError.emailNotFound
            }

            do {
                _ = try await Auth.auth().signIn(
                    withEmail: cleanIdentifier,
                    password: password
                )
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

        // USERNAME LOGIN
        let usernameSnapshot = try await db.collection("users")
            .whereField("username_lowercase", isEqualTo: cleanIdentifier)
            .limit(to: 1)
            .getDocuments()

        guard let document = usernameSnapshot.documents.first,
              let email = document.data()["email"] as? String else {
            throw AuthError.usernameNotFound
        }

        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
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
    }

    func currentUser() -> User? {
        Auth.auth().currentUser
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
