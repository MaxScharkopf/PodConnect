//
//  MapModel.swift
//  PodConnect
//
//  Created by Noah Hester on 3/9/26.
//

import FirebaseFirestore
import CoreLocation
import Foundation

// HTTP Response data structure
typealias MapResponse = [MapCategory]

/*
 
 Location categories for reference
 
 Bell Tower East
 Recreation Areas
 Bell Tower
 Open Areas
 Bell Tower West
 Buildings and Spaces
 Classrooms
 Gardens
 
 */

// Data structure for JSON decoding
struct MapCategory: Decodable {
    let name: String
    let catId: Int
    let children: Children?
}

// Child structure to match the JSON data
struct Children: Decodable {
    let locations: [MapLocation]?
    let categories: [MapCategory]?
}

// Location structure
struct MapLocation: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let lat: Double
    let lng: Double
    let catId: Int?
}

struct MapPin: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var latitude: Double
    var longitude: Double
    var category: String?
    var subtitle: String?
    var pinType: String
    var ownerUserId: String?
    var createdAt: Timestamp?
}
extension MapPin {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// Convert current pins into MapPins. Will not need later
extension MapLocation {
    func toMapPin(categoryName: String?) -> MapPin {
        MapPin(
            id: "campus-\(id)",
            name: name,
            latitude: lat,
            longitude: lng,
            category: categoryName,
            subtitle: nil,
            pinType: "campus",
            ownerUserId: nil,
            createdAt: nil
        )
    }
}
