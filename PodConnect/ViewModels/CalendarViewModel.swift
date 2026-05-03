//
//  CalendarViewModel.swift
//  PodConnect
//
//  Created by Maxwell Scharkopf on 4/13/26.
//

import Combine
import Foundation

@MainActor
class CalendarViewModel: ObservableObject {
    // The event repository for abstract database interaction
    private var eventRepository: EventRepository

    // Holds the user-created events for the signed-in user
    @Published var userEvents: [UserEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init(eventRepository: EventRepository) {
        self.eventRepository = eventRepository

        Task { await fetchEvents() }
    }

    func fetchEvents() async {
        // Set loading flag
        self.isLoading = true

        do {
            // Retrieve user events from Firestore
            let events = try await eventRepository.fetchEvents()

            // Set the events for view access
            self.userEvents = events

            // Clear loading and error state
            self.isLoading = false
            self.errorMessage = nil
        } catch {
            // Set error message
            errorMessage = error.localizedDescription
        }
    }

    func saveEvents(_ events: [UserEvent]) async {
        do {
            for event in events {
                try await eventRepository.saveEvent(event: event)
            }
            userEvents.append(contentsOf: events)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateEvent(event: UserEvent) async {
        do {
            try await eventRepository.updateEvent(event: event)
            if let index = userEvents.firstIndex(where: { $0.id == event.id }) {
                userEvents[index] = event
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateEventSeries(groupId: String, template: UserEvent) async {
        do {
            try await eventRepository.updateEventSeries(groupId: groupId, template: template)
            // Refresh from Firestore to get all updated instances
            await fetchEvents()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteEvent(event: UserEvent) async {
        do {
            // Remove the event from Firestore
            try await eventRepository.deleteEvent(event: event)

            // Remove locally
            userEvents.removeAll { $0.id == event.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteEventSeries(groupId: String) async {
        do {
            try await eventRepository.deleteEventSeries(groupId: groupId)

            // Remove all instances locally
            userEvents.removeAll { $0.recurrenceGroupId == groupId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
