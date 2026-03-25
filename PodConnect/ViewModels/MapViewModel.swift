//
//  MapViewModel.swift
//  PodConnect
//
//  Created by Noah Hester on 3/11/26.
//

import Combine
import Foundation

@MainActor
class MapViewModel: ObservableObject {
    // Store all map locations
    @Published var mapLocations: [MapLocation] = []
    //Dictionary mapping from ID number to
    @Published var locationCategories: [Int: String] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        // Start fetching the locations asyncronously
        Task { await fetchMapLocations() }
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
}
