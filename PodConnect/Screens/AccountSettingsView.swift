//
//  AccountSettingsView.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 3/28/26.
//

import Foundation
import SwiftUI
import FirebaseAuth

struct AccountSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""

    @State private var errorMessage = ""
    @State private var successMessage = ""

    @FocusState private var currentPasswordFocused: Bool
    @FocusState private var newPasswordFocused: Bool
    @FocusState private var confirmNewPasswordFocused: Bool

    private let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)
    private let ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topHeader

                ScrollView {
                    VStack(spacing: 20) {
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        if !successMessage.isEmpty {
                            Text(successMessage)
                                .foregroundColor(.green)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Change Password")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                SecureField("Current Password", text: $currentPassword)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($currentPasswordFocused)

                                SecureField("New Password", text: $newPassword)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($newPasswordFocused)

                                SecureField("Confirm New Password", text: $confirmNewPassword)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($confirmNewPasswordFocused)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                            

                            VStack(spacing: 0) {
                                Button("Update Password") {
                                    dismissKeyboard()
                                    Task {
                                        await updatePassword()
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                        }
                        
                        NavigationLink {
                            CanvasImportView()
                        } label: {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(ChannelClay)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Connect Canvas")
                                        .foregroundColor(.primary)

                                    Text("Import assignments from Canvas")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissKeyboard()
                    }
    
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var topHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .font(.system(size: 19, weight: .semibold))
                    .padding(8)
            }

            Text("Account Settings")
                .foregroundColor(.white)
                .font(.title)
                .fontWeight(.bold)

            Spacer()

            Color.clear
                .frame(width: 50, height: 50)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 18)
        .background(IslandsBlue)
    }

    private func dismissKeyboard() {
        currentPasswordFocused = false
        newPasswordFocused = false
        confirmNewPasswordFocused = false
    }

    private func friendlyAuthMessage(from error: Error) -> String {
        let nsError = error as NSError

        guard nsError.domain == AuthErrorDomain,
              let code = AuthErrorCode(rawValue: nsError.code) else {
            return "Something went wrong. Please try again."
        }

        switch code {
        case .wrongPassword, .invalidCredential:
            return "Incorrect password."
        case .requiresRecentLogin:
            return "Please sign out and sign back in, then try again."
        case .tooManyRequests:
            return "Too many attempts. Try again later."
        case .networkError:
            return "Network error. Please try again."
        default:
            return "Something went wrong. Please try again."
        }
    }

    private func updatePassword() async {
        errorMessage = ""
        successMessage = ""

        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            errorMessage = "No signed-in user found."
            return
        }

        if currentPassword.isEmpty || newPassword.isEmpty || confirmNewPassword.isEmpty {
            errorMessage = "Please fill in all password fields."
            return
        }

        if newPassword != confirmNewPassword {
            errorMessage = "Passwords do not match."
            return
        }

        do {
            let credential = EmailAuthProvider.credential(
                withEmail: email,
                password: currentPassword
            )

            try await user.reauthenticate(with: credential)
            try await user.updatePassword(to: newPassword)

            errorMessage = ""
            successMessage = "Password updated."

            currentPassword = ""
            newPassword = ""
            confirmNewPassword = ""
        } catch {
            successMessage = ""
            errorMessage = friendlyAuthMessage(from: error)
        }
    }
}

#Preview {
    NavigationView {
        AccountSettingsView()
    }
    .environmentObject(AssignmentsViewModel())
}
