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
    
    // Fetch filtered selection of documents from a collection
    func fetchCollection<T: Decodable>(path: String, configure: ((CollectionReference) -> Query)? = nil) async throws -> [T] {
        let collectionReference = db.collection(path)
        
        // Construct the firestore query based on the configuration function
        let query = configure?(collectionReference) ?? collectionReference
        
        let snapshot = try await query.getDocuments()
        
        // Format the snapshot into our desired data format
        return try snapshot.documents.map { try $0.data(as: T.self) }
    }
    
    // Fetch documents and listen for changes
    func createCollectionListener<T: Decodable>(path: String, configure: ((CollectionReference) -> Query)? = nil) -> AsyncThrowingStream<[T], Error> {
        // Create a stream for listening to updates
        AsyncThrowingStream { continuation in
            let collectionReference = db.collection(path)
            
            // Construct the firestore query based on the configuration function
            let query = configure?(collectionReference) ?? collectionReference
            
            // Construct a listener for the query to check for updates
            let listener = query.addSnapshotListener { snapshot, error in
                if let error = error {
                    // End the stream and throw an error
                    continuation.finish(throwing: error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    // Return empty if no documents
                    continuation.yield([])
                    return
                }
                
                // Yield the documents if found
                do {
                    let items = try documents.map { try $0.data(as: T.self) }
                    
                    continuation.yield(items)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            // Remove the listener when terminating the stream
            continuation.onTermination = { @Sendable _ in
                listener.remove()
            }
        }
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
    
    // Update document with specific ID after encoding them from the app usage data types
    func updateDocument<T: Encodable>(path: String, documentId: String, data: T) async throws {
        try db.collection(path).document(documentId).setData(from: data, merge: true)
    }
    
    // Remove a specific document from firestore
    func removeDocument(path: String, documentId: String) async throws {
        try await db.collection(path).document(documentId).delete()
    }
    
    // Get the count of documents in a collection or query
    func getCount(path: String, configure: ((CollectionReference) -> Query)? = nil) async throws -> Int {
        let collectionReference = db.collection(path)
        let query = configure?(collectionReference) ?? collectionReference
        let snapshot = try await query.count.getAggregation(source: .server)
        return Int(truncating: snapshot.count)
    }
}
