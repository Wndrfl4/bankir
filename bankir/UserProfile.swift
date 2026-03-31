import SwiftData
import Foundation

@Model
final class UserProfile {
    var id: UUID
    var username: String
    var email: String
    var notificationsEnabled: Bool
    var createdAt: Date

    init(id: UUID = UUID(), username: String, email: String, notificationsEnabled: Bool = true, createdAt: Date = .now) {
        self.id = id
        self.username = username
        self.email = email
        self.notificationsEnabled = notificationsEnabled
        self.createdAt = createdAt
    }
}

extension UserProfile {
    static let sample = UserProfile(username: "Aslan", email: "user@example.com")
}
