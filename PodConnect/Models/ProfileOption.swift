//
//  ProfileOption.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 4/14/26.
//

import Foundation
import FirebaseFirestore

struct ProfileOption: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
}
