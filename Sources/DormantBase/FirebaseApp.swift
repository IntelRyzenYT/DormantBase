//
//  FirebaseAuth.swift
//  DormantBase
//
//  Created by Samarth Bhate on 8/9/26.
//

import Foundation

/// Firebase needs to have shared mutable state
@MainActor
public final class FirebaseApp {
    public static let shared = FirebaseApp()

    private init() {}

    private(set) public var apiKey: String = ""
    private(set) public var projectID: String = ""

    public func setApiKey(_ key: String) {
        apiKey = key
    }
    
    public func setProjectID(_ id: String) {
        projectID = id
    }
}

