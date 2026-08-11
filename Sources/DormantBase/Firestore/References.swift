//
//  References.swift
//  DormantBase
//
//  Created by Samarth Bhate on 8/9/26.
//

import Foundation

public struct SendableDocumentData: @unchecked Sendable {
    public let fields: [String: Any]
    
    public init(_ fields: [String: Any]) {
        self.fields = fields
    }
}


/// this hopefully would not cause any problems
/// *foreshadowing*
public struct DocumentReference: @unchecked Sendable {
    enum DocumentReferenceError: LocalizedError {
        case failedToAccessDocumentURL
        case failedToParseFirestoreFields
        
        var errorDescription: String? {
            switch self {
            case .failedToAccessDocumentURL:
                "Failed to access document URL"
            case .failedToParseFirestoreFields:
                "Failed to parse Fields"
                
            }
        }
    }
    let path: String
    
    let firestore: Firestore
    
    init(path: String, firestore: Firestore) {
        self.path = path
        self.firestore = firestore
    }
    
    /// fieldref
    public func field(_ fieldName: String) -> FieldReference {
        FieldReference(documentPath: path, fieldName: fieldName, firestore: firestore)
    }
    
    private func documentURL() async -> URL? {
        URL(string: "\(await firestore.baseURL)/\(path)")
    }
    
    private func authenticatedURL() async -> URL? {
        guard let url = await documentURL() else { return nil }
        guard await FirebaseApp.shared.apiKey != "" else { return url }
        let apiKey = await FirebaseApp.shared.apiKey
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = (components?.queryItems ?? [])
            .filter { $0.name != "key" }
        
        var updatedQueryItems = queryItems
        updatedQueryItems.append(URLQueryItem(name: "key", value: apiKey))
        components?.queryItems = updatedQueryItems
        
        return components?.url ?? url
    }
    
    public func getDocument() async throws -> Result<[String: Any], Error> {
        guard let url = await authenticatedURL() else { return .failure(DocumentReferenceError.failedToAccessDocumentURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        print(url.absoluteString)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print(String(data: data, encoding: .utf8) ?? "response is nil for some odd reason")
            guard let parsedData = FirestoreFieldMapper.decode(data) else {
                throw DocumentReferenceError.failedToParseFirestoreFields
            }
            return .success(parsedData)
        } catch {
            return .failure(error)
        }
        
    }
    
    public func setData(_ data: [String: Any]) async throws {
        guard let url = await authenticatedURL(),
              let payload = FirestoreFieldMapper.encode(data) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = payload
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
    
    public func delete() async throws {
        guard let url = await authenticatedURL() else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
    
    public func addSnapshotListener(
        interval: TimeInterval = 5.0,
        listener: @escaping @Sendable (Result<SendableDocumentData, Error>) -> Void
    ) async {
        let registration = ListenerRegistration.shared
        
        // Fetch fresh data INSIDE the closure on every tick
        await registration.register {
            do {
                let result = try await self.getDocument()
                
                switch result {
                case .success(let data):
                    // Wrap the unsafe [String: Any] in our Sendable struct
                    listener(.success(SendableDocumentData(data)))
                case .failure(let error):
                    listener(.failure(error))
                }
            } catch {
                listener(.failure(error))
            }
        }
    }
}

/// This one too...

public struct CollectionReference: @unchecked Sendable {
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

/// THERE's TOO MANY UNCHECKED SENDABLES IN THIS FILE, I HOPE THIS DOESN'T CAUSE ANY PROBLEMS!!!

public struct FieldReference: @unchecked Sendable {
    public let documentPath: String
    public let fieldName: String
    let firestore: Firestore
    
    public enum FieldType {
        case stringValue(stringValue: String)
        case nullValue
        case booleanValue(booleanValue: Bool)
        case integerValue(integerValue: Int)
        case doubleValue(doubleValue: Double)
        case timestamp(timestampValue: Date)
        case geoPointValue(geoPointValue: LatLng)
        case arrayValue(arrayValue: Array<Any>)
        case mapValue(mapValue: Dictionary<AnyHashable, AnyHashable>)
    }
    
    public init(documentPath: String, fieldName: String, firestore: Firestore) {
        self.documentPath = documentPath
        self.fieldName = fieldName
        self.firestore = firestore
    }

    private func documentURL() async -> URL? {
        URL(string: "\(await firestore.baseURL)/\(documentPath)")
    }

    private func authenticatedURL() async -> URL? {
        guard let url = await documentURL() else { return nil }
        guard await FirebaseApp.shared.apiKey != "" else { return url }
        let apiKey = await FirebaseApp.shared.apiKey

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = (components?.queryItems ?? [])
            .filter { $0.name != "key" }

        var updatedQueryItems = queryItems
        updatedQueryItems.append(URLQueryItem(name: "key", value: apiKey))
        components?.queryItems = updatedQueryItems

        return components?.url ?? url
    }
    
    public func get() async throws -> FieldReference.FieldType {
        let document = await firestore.document(documentPath)
        let result = try await document.getDocument()

        switch result {
        case .success(let data):
            return fieldType(from: data[fieldName])
        case .failure(let error):
            throw error
        }
    }

    public func setData(_ data: FieldReference.FieldType) async throws {
        guard let url = await authenticatedURL() else { return }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? []
        queryItems.append(URLQueryItem(name: "updateMask.fieldPaths", value: fieldName))
        components?.queryItems = queryItems

        let payload: [String: Any] = [
            "fields": [
                fieldName: FirestoreFieldMapper.encodeFieldValue(data)
            ]
        ]

        var request = URLRequest(url: components?.url ?? url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, _) = try await URLSession.shared.data(for: request)
    }

    private func fieldType(from value: Any?) -> FieldReference.FieldType {
        switch value {
        case let value as String:
            return .stringValue(stringValue: value)
        case let value as Bool:
            return .booleanValue(booleanValue: value)
        case let value as Int:
            return .integerValue(integerValue: value)
        case let value as Double:
            return .doubleValue(doubleValue: value)
        case let value as Date:
            return .timestamp(timestampValue: value)
        case let value as LatLng:
            return .geoPointValue(geoPointValue: value)
        case let value as [Any]:
            return .arrayValue(arrayValue: value)
        case let value as [AnyHashable: AnyHashable]:
            return .mapValue(mapValue: value)
        case _ as NSNull, nil:
            return .nullValue
        default:
            return .nullValue
        }
    }
    
    
    @available(*, deprecated, message: "Use FieldReference.get() instead.")
    public func getField(_ fieldName: String) -> FieldType {
        return .nullValue
    }
}

/// At least this one is checked lol

public struct LatLng: Codable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

