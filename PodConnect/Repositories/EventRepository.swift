//
//  EventRepository.swift
//  PodConnect
//
//  Created by Maxwell Scharkopf on 4/13/26.
//


import FirebaseAuth
internal import FirebaseFirestoreInternal

class EventRepository {
    private var firestoreService: FirestoreService
    private var authService: AuthService
    
    init(firestoreService: FirestoreService, authService: AuthService) {
        self.firestoreService = firestoreService
        self.authService = authService
    }
    
    func fetchEvents() async throws -> [UserEvent] {
        
        // Check if user is logged in
        guard let userId = authService.userInfo?.id else {
            return []
        }
        
        // Fetch only events that user owns
        let events: [UserEvent] = try await
        firestoreService.fetchCollection(path: "events") { query in
            query.whereField("uid", isEqualTo: userId)}
        
        return events
    }
}

    
    
