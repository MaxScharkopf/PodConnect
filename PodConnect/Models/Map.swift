//
//  MapModel.swift
//  PodConnect
//
//  Created by Noah Hester on 3/9/26.
//

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
struct MapLocation: Decodable, Identifiable {
    let id: Int
    let name: String
    let lat: Double
    let lng: Double
    let catId: Int?
}
