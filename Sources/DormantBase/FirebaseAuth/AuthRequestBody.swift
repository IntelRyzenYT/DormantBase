//
//  AuthRequestBody.swift
//  DormantBase
//
//  Created by Samarth Bhate on 8/11/26.
//


internal struct AuthRequestBody: Codable {
    var email: String
    var password: String
    var returnSecureToken: Bool = true
}

internal struct AuthResponseBody: Codable {
    var idToken: String
    var email: String
    var refreshToken: String
    var expiresIn: String
    var localId: String
    var registered: Bool
}

internal struct RefreshTokenResponse: Codable {
    var access_token: String
    var expires_in: String
    var token_type: String
    var refresh_token: String
    var id_token: String
    var user_id: String
    var project_id: String
}
