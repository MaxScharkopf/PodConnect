//
//  PodConnectApp.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 3/8/26.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct PodConnectApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    private let firestore = FirestoreService()
    private let auth: AuthService
    
    init() {
        auth = AuthService(firestoreService: firestore)
    }
    
    
    var body: some Scene {
        WindowGroup {
            ContentView(authService: auth, firestoreService: firestore)
                .onAppear {
                    auth.startAuthListener()
                }
        }
    }
}
