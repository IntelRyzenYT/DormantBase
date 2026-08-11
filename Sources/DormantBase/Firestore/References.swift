//
//  DocumentReference.swift
//  DormantBase
//
//  Created by Samarth Bhate on 8/9/26.
//


public class DocumentReference {
    let path: String
    let firestore: Firestore
    
    init(path: String, firestore: Firestore) {
        self.path = path
        self.firestore = firestore
    }
}

public class CollectionReference {
    let path: String
    let firestore: Firestore
    
    init(path: String, firestore: Firestore) {
        self.path = path
        self.firestore = firestore
    }
    
    public func document(_ documentId: String) -> DocumentReference {
        return DocumentReference(path: "\(path)/\(documentId)", firestore: firestore)
    }
}