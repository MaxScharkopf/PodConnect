//
//  PodConnectApp.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 3/8/26.
//

import SwiftUI
import FirebaseCore

@main
struct YourApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                 ContentView() //UNCOMMENT AFTER FIRST SPRINT DEMO
               // AuthView(onAuthenticated: {
               //     print("User logged in")
               // })
                // MapView() COMMENTING OUT TO TEST SIGN UP
            }
        }
    }
}
