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
    // Create database reference
    private lazy var db = Firestore.firestore()
    
    // Fetch firestore documents and put them into decodable data types for app usage
    func fetchCollection<T: Decodable>(path: String) async throws -> [T] {
        let snapshot = try await db.collection(path).getDocuments()
        
        // Format into data structures
        return try snapshot.documents.map { try $0.data(as:T.self) }
    }
    
    // Fetch filtered selection of documents from a collection
    func fetchCollection<T: Decodable>(path: String, configure: (CollectionReference) -> Query) async throws -> [T] {
        // Construct the firestore query based on the configuration function
        let query = configure(db.collection(path))
        
        let snapshot = try await query.getDocuments()
        
        // Format the snapshot into our desired data format
        return try snapshot.documents.map { try $0.data(as: T.self) }
    }
    
    // Fetch documents and listen for changes
    func createCollectionListener<T: Decodable>(path: String, configure: (CollectionReference) -> Query) async throws -> [T] {
       // TODO: Add snapshot listener
        return []
    }
    
    // Fetch one specific document
    func fetchDocument<T: Decodable>(path: String, documentId: String) async throws -> T? {
        // Get the data snapshot of the one single document
        let snapshot = try await db.collection(path).document(documentId).getDocument()
        
        guard snapshot.exists else { return nil }
        
        // Format the data to match decodable type
        return try snapshot.data(as: T.self)
    }
    
    // Save document to firestore with auto generated ID after encoding them from the app usage data types
    func saveDocument<T: Encodable>(path: String, data: T) async throws {
        try db.collection(path).document().setData(from: data)
    }
    
    // Save document with specific ID to firestore after encoding them from the app usage data types
    func saveDocument<T: Encodable>(path: String, documentId: String, data: T) async throws {
        try db.collection(path).document(documentId).setData(from: data)
    }
    
    // Remove a specific document from firestore
    func removeDocument(path: String, documentId: String) async throws {
        try await db.collection(path).document(documentId).delete()
    }
}
