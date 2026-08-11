//
//  FirebaseAuth.swift
//  DormantBase
//
//  Created by Samarth Bhate on 8/11/26.
//

//
//  FirebaseAuth.swift
//  Test_gRPC
//
//  Created by Samarth Bhate on 8/6/26.
//

import Foundation
import Combine
import Security

import KeychainSwift
import JWTDecode



@Observable @MainActor
public class FirebaseAuth {
    public static let shared = FirebaseAuth()
    public var currentUser: User? = nil
    
    
    /// FirebaseAuth.AuthError
    public enum AuthError: Error {
        case invalidIdToken
    }
    
    private init() {
        let apikey = FirebaseApp.shared.apiKey
        guard apikey != "" else {
            return
        }
        /// Attempt to refresh token if refreshToken exists in Keychain
        let keychain = KeychainSwift()
        if let refreshToken = keychain.get("refreshToken") {
            Task {
                do {
                    /// Prepare URL and request to refresh the ID token using the refresh token
                    let url = URL(string: "https://securetoken.googleapis.com/v1/token?key=\(apikey)")!
                    var request = URLRequest(url: url)
                    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                    request.httpMethod = "POST"
                    
                    /// Set the request body with the refresh token grant
                    let bodyString = "grant_type=refresh_token&refresh_token=\(refreshToken)"
                    request.httpBody = bodyString.data(using: .utf8)
                    
                    /// Perform the network request
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    /// Check for valid HTTP response status code
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        return
                    }

                    /// Decode the refresh token response
                    let refreshResponse = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
                    
                    /// Update the refreshToken in Keychain with the new one
                    keychain.set(refreshResponse.refresh_token, forKey: "refreshToken")
                    
                    /// Get idToken
                    let idToken = refreshResponse.id_token
                    
                    /// Update currentUser with info from refresh token response
                    let (uid, email, isEmailVerified) = try decodeIDToken(idToken)
                    
                    FirebaseAuth.shared.currentUser = User (
                        uid: uid,
                        email: email,
                        isEmailVerified: true
                    )
                    
                } catch {
                    print("There was an error refreshing \(error)")
                }
            }
        }
    }
    
    public func signIn(with email: String, password: String) async throws {
        let apikey = FirebaseApp.shared.apiKey
        guard apikey != "" else { return }
        
        /// endpoint
        let url = URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=\(apikey)")!
        
        /// setup post request
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        
        /// always set  `returnSecureToken` to true
        let body = AuthRequestBody(
            email: email, password: password
        )
        
        let jsonBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.upload(for: request, from: jsonBody)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let jsonResponse = try JSONDecoder().decode(AuthResponseBody.self, from: data)
        
        let keychain = KeychainSwift()
        
        /// Save it to keychian
        keychain.set(jsonResponse.refreshToken, forKey: "refreshToken")
        
        /// Get idToken
        let idToken = jsonResponse.idToken
        
        /// Update currentUser with info from refresh token response
        let (uid, email, isEmailVerified) = try decodeIDToken(idToken)
        
        FirebaseAuth.shared.currentUser = User (
            uid: uid,
            email: email,
            isEmailVerified: true
        )
        
    }
    
    
    private func decodeIDToken(_ idToken: String) throws -> (uid: String, email: String, isEmailVerified: Bool) {
        /// Decode idToken's JWT
        let decodedJWT = try decode(jwt: idToken)
        
        /// Get componnts
        guard let uid = decodedJWT.subject,
              let email = decodedJWT.claim(name: "email").string,
          //    let name = decodedJWT.claim(name: "name").string,
              let isEmailVerified = decodedJWT.claim(name: "email_verified").boolean else {
            throw AuthError.invalidIdToken
        }
        
        /// return components
        return (
            uid: uid,
            email: email,
            isEmailVerified: isEmailVerified
        )
              
    }
}


