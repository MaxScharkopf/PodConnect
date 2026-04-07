
//
//  AuthView.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 3/28/26.
//

import SwiftUI

struct AuthView: View {
    @State private var isSignUp = false
    @State private var identifier = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    @ObservedObject var authService: AuthService
    
    private var trimmedUsername: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var passwordsDoNotMatch: Bool {
        isSignUp && !confirmPassword.isEmpty && password != confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 80)

                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(isSignUp ? "Create your PodConnect account" : "Sign in with email or username")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 16) {
                        if isSignUp {
                            TextField("Username", text: $username)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }

                        TextField(isSignUp ? "Email" : "Email or Username", text: $identifier)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)

                        if isSignUp {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(.roundedBorder)

                            if passwordsDoNotMatch {
                                Text("Passwords do not match")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(spacing: 0) {
                        Button {
                            Task {
                                await submit()
                            }
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .disabled(buttonDisabled)
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }

                Button(isSignUp ? "Already have an account? Sign In" : "Need an account? Create One") {
                    isSignUp.toggle()
                    errorMessage = ""
                    password = ""
                    confirmPassword = ""
                }
                .font(.footnote)

                Spacer(minLength: 80)
            }
            .padding(24)
        }
    }

    private var buttonDisabled: Bool {
        if isLoading || identifier.isEmpty || password.isEmpty {
            return true
        }

        if isSignUp {
            return passwordsDoNotMatch || confirmPassword.isEmpty || trimmedUsername.isEmpty
        }

        return false
    }

    func submit() async {
        errorMessage = ""

        if isSignUp {
            if password != confirmPassword {
                errorMessage = "Passwords do not match"
                return
            }
        }

        isLoading = true

        do {
            if isSignUp {
                try await authService.signUp(
                    email: identifier,
                    password: password,
                    username: trimmedUsername
                )
            } else {
                try await authService.signIn(
                    identifier: identifier,
                    password: password
                )
            }
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "Something went wrong."
        } catch {
            errorMessage = "Something went wrong."
        }

        isLoading = false
    }
}

#Preview {
    AuthView(authService: AuthService(firestoreService: FirestoreService()))
}
