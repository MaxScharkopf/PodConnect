//
//  FirestoreService.swift
//  PodConnect
//
//  Created by Noah Hester on 3/27/26.
//

/*
 
 This is the core service for interacting with Firestore in order to eliminate the direct access from higher level classes
 
 */

import FirebaseFirestore

// Generalized class for fetching and saving documents into abstract codable types
final class FirestoreService {
    private let db = Firestore.firestore()
}
