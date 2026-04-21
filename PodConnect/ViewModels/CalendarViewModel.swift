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
    @Published var schoolEvents: [SchoolEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init(eventRepository: EventRepository) {
        self.eventRepository = eventRepository

        Task {
            await fetchEvents()
            await fetchSchoolEvents()
        }
    }

    func fetchSchoolEvents() async {
        do {
            schoolEvents = try await eventRepository.fetchSchoolEvents()
        } catch {
            errorMessage = error.localizedDescription
        }
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

    func saveEvent(event: UserEvent) async {
        do {
            // Persist the event to Firestore
            try await eventRepository.saveEvent(event: event)

            // Append locally to avoid a full refetch
            userEvents.append(event)
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
}
