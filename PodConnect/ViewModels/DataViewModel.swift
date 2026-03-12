//
//  DataViewModel.swift
//  PodConnect
//
//  Created by Noah Hester on 3/9/26.
//

import Combine
import FirebaseFirestore

class DataViewModel: ObservableObject {
    // Firestore database
    private let db: Firestore
    // Holds more general map information
    @Published var mapData: MapData?
    // Holds the specific locations we are currently viewing
    @Published var locations: [Location] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    init() async throws {
        // Initialize the database
        db = Firestore.firestore()
        
        // Load the static map data
        await loadMapData()
    }
    
    private func loadMapData() async {
        self.isLoading = true
        
        // Reference to the map document from the static data collection
        let docRef = db.collection("static").document("map")
        
        do {
            // Fetch the document information
            let result = try await docRef.getDocument(as: MapData.self)
            
            self.errorMessage = nil
            self.isLoading = false
            
            // Save the data
            self.mapData = result
        }catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    private func queryMapLocations(fields: [String], values: [String]) async {
        self.isLoading = true
        
        let collectionRef = db.collection("static").document("map").collection("locations")
        var query: Query = collectionRef
        
        for (field, value) in zip(fields, values) {
            //query = query.whereField(query, isEqualTo: value)
        }
        
        do {
            let snapshot = try await query.getDocuments()
            
            self.errorMessage = nil
            self.isLoading = false
            
            self.locations = snapshot.documents.compactMap { document in
                try? document.data(as: Location.self)
            }
        }catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}
