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
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    lazy var firestore = FirestoreService()
    lazy var auth = AuthService()
    lazy var messageRepository = MessageRepository(firestoreService: firestore, authService: auth)
    lazy var messageViewModel = MessageViewModel(messageRepository: messageRepository)
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
