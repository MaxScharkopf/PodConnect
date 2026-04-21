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
    
    func saveEvent(event: UserEvent) async throws {

        // Check if user is logged in
        guard let userId = authService.userInfo?.id else {
            return
        }

        // Stamp the owner's uid onto the event before saving
        var eventWithUID = event
        eventWithUID.uid = userId

        // Save the event to the events collection
        try await firestoreService.saveDocument(path: "events", documentId: eventWithUID.id.uuidString, data: eventWithUID)
    }
    
    func deleteEvent(event: UserEvent) async throws {

        // Check if user is logged in
        guard let userId = authService.userInfo?.id else {
            return
        }

        // Remove the event document using the event's unique ID
        try await firestoreService.removeDocument(path: "events", documentId: event.id.uuidString)
    }

    func fetchSchoolEvents() async throws -> [SchoolEvent] {
        return try await firestoreService.fetchCollection(path: "schoolEvents") { query in
            query.order(by: "date", descending: false)
        }
    }

}

    
    
