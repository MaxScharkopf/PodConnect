//
//  MapModel.swift
//  PodConnect
//
//  Created by Noah Hester on 3/9/26.
//

import Foundation

typealias MapResponse = [MapCategory]

struct MapCategory: Decodable {
    let name: String?
    let catId: Int?
    let children: Children?
}

struct Children: Decodable {
    let locations: [Location]?
    let categories: [MapCategory]?
}

struct Location: Decodable, Identifiable {
    let id: Int
    let name: String
    let lat: Double
    let lng: Double
    let catId: Int?
    let mapId: Int?
}
