//
//  PodConnectApp.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 3/8/26.
//

import SwiftUI

@main
struct YourApp: App {
    let firestore = FirestoreService()
    let auth = AuthService()
    
    lazy var messageRepository = MessageRepository(firestoreService: firestore, authService: auth)
    lazy var messageViewModel = MessageViewModel(messageRepository: messageRepository)
    
    var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
      }
    }
  }
}
