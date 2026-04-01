//
//  AuthService.swift
//  PodConnect
//
//  Created by Noah Hester on 3/27/26.
//

import Combine
import FirebaseAuth

final class AuthService {
    @Published var currentUser: UserInfo?

    init() {
        // Dummy user for testing (has real ID #)
        self.currentUser = UserInfo(id: "rsvu3jzGJdMjmMl6i1gWpY472Gs1", username: "dummy_user", friends: [])
    }
}
