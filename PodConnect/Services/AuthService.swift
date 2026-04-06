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
    @Published var currentUser: User? = nil
    @Published var userInfo: UserInfo? = nil
    @Published var isAuthenticated: Bool = false
    
    private var firestoreService: FirestoreService
    private var authHandle: AuthStateDidChangeListenerHandle?
    
    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }
    
    // This creates a listener that will wait for any auth changes and adjust things accordingly as it happens
    func startAuthListener() {
        // Check if the auth handle exists
        guard authHandle == nil else { return }

        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            
            self.currentUser = user
            self.isAuthenticated = (user != nil)
            
            // If we have a user, fetch their profile from Firestore
            if let user = user {
                Task {
                    do {
                        let profile: UserInfo? = try await self.firestoreService.fetchDocument(path: "users", documentId: user.uid)
                        
                        // Because this runs in a Task, we must update the @Published property on the Main Actor
                        await MainActor.run {
                            self.userInfo = profile
                        }
                    } catch {
                        print("Failed to fetch user info: \(error)")
                    }
                }
            } else {
                self.userInfo = nil // Clear it out if they logged out
            }
        }
    }
    
    // Creates a new Firebase Auth user and corresponding Firestore profile.
    func signUp(email: String, password: String, username: String?) async throws {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanUsername = username?.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for users that already have that name
        if let cleanUsername, !cleanUsername.isEmpty {
            let matchingUsers: [UserInfo] = try await firestoreService.fetchCollection(path: "users") { document in
                document
                    .whereField("username_lowercase", isEqualTo: cleanUsername.lowercased())
                    .limit(to: 1)
            }

            if !matchingUsers.isEmpty {
                throw AuthError.usernameAlreadyTaken
            }
        }
        
        do {
            guard let username_lower = cleanUsername?.lowercased() else {
                throw AuthError.usernameNotFound
            }
            
            let result = try await Auth.auth().createUser(
                withEmail: cleanEmail,
                password: password
            )

            let profile = UserInfo(
                id: nil,
                username: cleanUsername ?? "",
                username_lowercase: username_lower,
                classes: [],
                clubs: [],
                email: cleanEmail,
                uid: result.user.uid,
                bio: ""
            )

            try await firestoreService.saveDocument(path: "users", documentId: result.user.uid, data: profile)
            
            self.userInfo = profile

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
        let email: String

        // Handle getting user email before do {...} catch for efficiency
        if cleanIdentifier.contains("@") {
            // Get users that match this username
            let users: [UserInfo] = try await firestoreService.fetchCollection(path: "users") { document in
                document.whereField("email", isEqualTo: cleanIdentifier).limit(to: 1)
            }
            
            guard let matchedUser = users.first else {
                throw AuthError.usernameNotFound
            }
            
            email = cleanIdentifier

        }else {
            // Get users that match this username
            let users: [UserInfo] = try await firestoreService.fetchCollection(path: "users") { document in
                document.whereField("username_lowercase", isEqualTo: cleanIdentifier).limit(to: 1)
            }
            
            guard let matchedUser = users.first else {
                throw AuthError.usernameNotFound
            }
            
            email = matchedUser.email
        }

        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
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
    
    // Saves profile changes while preserving case-insensitive username lookup.
    func updateUserProfile(_ profile: UserInfo) async throws {
        let trimmedUsername = profile.username.trimmingCharacters(in: .whitespacesAndNewlines)

        // Get users that match this username
        let users: [UserInfo] = try await firestoreService.fetchCollection(path: "users") { document in
            document
                .whereField("username_lowercase", isEqualTo: trimmedUsername.lowercased())
                .limit(to: 1)
        }

        let isTaken = users.contains { $0.id != profile.uid }

        if isTaken {
            throw AuthError.usernameAlreadyTaken
        }
        
        try await firestoreService.updateDocument(path: "users", documentId: profile.uid, data: profile)
        
        await MainActor.run {
            self.userInfo = profile
        }
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
