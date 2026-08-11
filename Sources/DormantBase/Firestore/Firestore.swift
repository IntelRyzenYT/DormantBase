//
//  Firestore.swift
//  DormantBase
//
//  Created by Samarth Bhate on 8/9/26.
//

import Foundation

@Observable @MainActor
public class Firestore {
    public static let shared = Firestore()
    
    private(set) var projectId: String
    private(set) var databaseId: String
    
    internal var baseURL: String {
        return "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/\(databaseId)/documents"
    }
    public func setDatabaseID(_ newID: String) {
        self.databaseId = newID
    }
    
    private init() {
        self.projectId = FirebaseApp.shared.projectID
        self.databaseId = "(default)"
    }
    
    public func configure(projectId: String, databaseId: String = "(default)") {
        self.projectId = projectId
        self.databaseId = databaseId
    }
    
    public func collection(_ collectionPath: String) -> CollectionReference {
        return CollectionReference(path: collectionPath, firestore: self)
    }
    
    public func document(_ documentPath: String) -> DocumentReference {
        return DocumentReference(path: documentPath, firestore: self)
    }
    
}


