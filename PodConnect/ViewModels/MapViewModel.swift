//
//  MapViewModel.swift
//  PodConnect
//
//  Created by Noah Hester on 3/11/26.
//

import Combine
import Foundation
import CoreLocation
import FirebaseFirestore

@MainActor
class MapViewModel: ObservableObject {
    // Store all map locations
    @Published var mapLocations: [MapLocation] = []
    // User pins from firebase
    @Published var userPins: [MapPin] = []
    //Dictionary mapping from ID number to
    @Published var locationCategories: [Int: String] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var mapRepository: MapRepository
    private var friendRepository: FriendRepository
    private var pinsListener: ListenerRegistration?

    // Converting current pins into MapPin. Later these will be stored in firebase
    var campusPins: [MapPin] {
        mapLocations.compactMap { location in
            let categoryName = location.catId.flatMap { locationCategories[$0] }
            return location.toMapPin(categoryName: categoryName)
        }
    }
    
    var allPins: [MapPin] {
        campusPins + userPins
    }

    init(mapRepository: MapRepository, friendRepository: FriendRepository) {
        self.mapRepository = mapRepository
        self.friendRepository = friendRepository
        // Start fetching the locations asyncronously
        Task {
            await fetchMapLocations()
            startListeningToPins()
        }
    }

    func fetchMapLocations() async {
        // Set flags and error
        isLoading = true
        errorMessage = nil

        // Form the URL for data retrieval
        guard let mapURL = URL(string:
            "https://api.concept3d.com/categories/4034,39247,24292,24293,75941,75942,75943,75944?map=502&batch&children&key=0001085cc708b9cef47080f064612ca5"
        ) else {
            errorMessage = "Error: Failed to form URL"
            isLoading = false
            return
        }

        do {
            // Retrieve the data and decode it
            let (data, _) = try await URLSession.shared.data(from: mapURL)
            let categories = try JSONDecoder().decode(MapResponse.self, from: data)

            // Clear the locations
            mapLocations.removeAll()
            locationCategories.removeAll()

            // Traverse the data and store it
            traverseCategories(categories: categories)
            
            // Set loading flag
            isLoading = false

        } catch {
            // Set error message
            errorMessage = "Error: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func loadUserPins() async {
        do {
            userPins = try await mapRepository.fetchCurrentUserPins()
        } catch {
            errorMessage = "Error loading user pins: \(error.localizedDescription)"
        }
    }

    func addUserPin(name: String, subtitle: String?, coordinate: CLLocationCoordinate2D, sharedWith: [String]) async -> MapPin? {
        do {
            let pin = try await mapRepository.createUserPin(
                name: name,
                subtitle: subtitle,
                coordinate: coordinate,
                sharedWith: sharedWith
            )
            await loadUserPins()
            return pin
        } catch {
            errorMessage = "Error saving pin: \(error.localizedDescription)"
            return nil
        }
    }
    
    func updateUserPin(id: String, name: String, subtitle: String?, sharedWith: [String]) async {
        do {
            try await mapRepository.updatePin(
                id: id,
                name: name,
                subtitle: subtitle,
                sharedWith: sharedWith
            )
            
            await loadUserPins()
            
        } catch {
            errorMessage = "Error updating pin: \(error.localizedDescription)"
        }
    }
    
    func deleteUserPin(id: String) async {
        do {
            try await mapRepository.deletePin(id: id)
            await loadUserPins()
        } catch {
            errorMessage = "Error deleting pin: \(error.localizedDescription)"
        }
    }

    func traverseCategories(categories: [MapCategory]?) {
        // Return if invalid category data
        guard let categories else { return }

        // Go through each
        for category in categories {
            // Store in the dictionary so we know which category ID maps to which category
            locationCategories[category.catId] = category.name
            
            // Add all locations
            if let locations = category.children?.locations {
                mapLocations.append(contentsOf: locations)
            }

            // Recursively traverse
            traverseCategories(categories: category.children?.categories)
        }
    }
    
    func startListeningToPins() {
        pinsListener?.remove()

        pinsListener = mapRepository.listenToVisiblePins { [weak self] pins in
            Task { @MainActor in
                self?.userPins = pins
            }
        }
    }
    
    func stopListeningToPins() {
        pinsListener?.remove()
        pinsListener = nil
    }
}
