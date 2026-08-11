//
//  User.swift
//  DormantBase
//
//  Created by Samarth Bhate on 8/11/26.
//


public struct User: Codable {
    var uid: String
    var email: String
    var isEmailVerified: Bool
    var displayName: String?
}
