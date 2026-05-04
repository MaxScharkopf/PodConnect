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

    func updateEvent(event: UserEvent) async throws {
        guard authService.userInfo?.id != nil else { return }
        try await firestoreService.saveDocument(path: "events", documentId: event.id.uuidString, data: event)
    }

    func updateEventSeries(groupId: String, template: UserEvent) async throws {
        guard let userId = authService.userInfo?.id else { return }

        let seriesEvents: [UserEvent] = try await firestoreService.fetchCollection(path: "events") { query in
            query.whereField("uid", isEqualTo: userId)
                 .whereField("recurrenceGroupId", isEqualTo: groupId)
        }

        let cal = Calendar.current
        let timeComponents = cal.dateComponents([.hour, .minute, .second], from: template.startDate)
        let duration = template.endDate.timeIntervalSince(template.startDate)

        for event in seriesEvents {
            var updated = event
            updated.title = template.title
            updated.notes = template.notes
            updated.category = template.category
            if let newStart = cal.date(bySettingHour: timeComponents.hour ?? 0,
                                       minute: timeComponents.minute ?? 0,
                                       second: 0, of: event.startDate) {
                updated.startDate = newStart
                updated.endDate = newStart.addingTimeInterval(duration)
            }
            try await firestoreService.saveDocument(path: "events", documentId: updated.id.uuidString, data: updated)
        }
    }

    func deleteEventSeries(groupId: String) async throws {

        // Check if user is logged in
        guard let userId = authService.userInfo?.id else {
            return
        }

        // Fetch all events in this series owned by the current user
        let seriesEvents: [UserEvent] = try await firestoreService.fetchCollection(path: "events") { query in
            query.whereField("uid", isEqualTo: userId)
                 .whereField("recurrenceGroupId", isEqualTo: groupId)
        }

        // Delete each instance
        for event in seriesEvents {
            try await firestoreService.removeDocument(path: "events", documentId: event.id.uuidString)
        }
    }

}

    
    
