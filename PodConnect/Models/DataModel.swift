//
//  DataModel.swift
//  PodConnect
//
//  Created by Noah Hester on 3/9/26.
//

import FirebaseFirestore

struct MapData: Codable {
    let campus_center: GeoPoint
}

class Location: Codable {
    @DocumentID var id: String?
    let name: String
    let type: String
    let location: GeoPoint
    let restrooms: Bool?
    let food: Bool?
    let description: String?
}

