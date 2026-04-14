import SwiftData
import Foundation

@Model
final class UserProfile {
    var id: UUID
    var encryptedUsername: Data
    var encryptedEmail: Data
    var notificationsEnabled: Bool
    var createdAt: Date

    // Computed properties для шифрования/дешифрования
    var username: String {
        get {
            do {
                return try SecurityUtils.decryptUserData(encryptedUsername)
            } catch {
                print("Error decrypting username: \(error)")
                return "" // Или обработка ошибки
            }
        }
        set {
            do {
                encryptedUsername = try SecurityUtils.encryptUserData(newValue)
            } catch {
                print("Error encrypting username: \(error)")
                // Обработка ошибки
            }
        }
    }
    
    var email: String {
        get {
            do {
                return try SecurityUtils.decryptUserData(encryptedEmail)
            } catch {
                print("Error decrypting email: \(error)")
                return ""
            }
        }
        set {
            do {
                encryptedEmail = try SecurityUtils.encryptUserData(newValue)
            } catch {
                print("Error encrypting email: \(error)")
                // Обработка ошибки
            }
        }
    }

    init(id: UUID = UUID(), username: String, email: String, notificationsEnabled: Bool = true, createdAt: Date = .now) {
        self.id = id
        self.notificationsEnabled = notificationsEnabled
        self.createdAt = createdAt
        
        // Шифруем при инициализации
        do {
            self.encryptedUsername = try SecurityUtils.encryptUserData(username)
            self.encryptedEmail = try SecurityUtils.encryptUserData(email)
        } catch {
            print("Error encrypting user data during init: \(error)")
            self.encryptedUsername = Data()
            self.encryptedEmail = Data()
        }
    }
}

extension UserProfile {
    static let sample = UserProfile(username: "Aslan", email: "user@example.com")
}
