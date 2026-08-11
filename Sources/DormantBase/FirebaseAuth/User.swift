struct User: Codable {
    var uid: String
    var email: String
    var isEmailVerified: Bool
    var displayName: String?
}