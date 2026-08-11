//
//  FirebaseAuth.swift
//  DormantBase
//
//  Created by Samarth Bhate on 8/9/26.
//

import Foundation

@MainActor
public final class FirebaseApp {
    public static let shared = FirebaseApp()

    private init() {}

    private(set) public var apiKey: String?

    public func setApiKey(_ key: String) {
        apiKey = key
    }
}

