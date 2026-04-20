import SwiftData
import Foundation

@Model
final class UserProfile {
    var id: UUID
    var encryptedUsername: Data
    var encryptedEmail: Data
    var encryptedPassword: Data?
    var roleRawValue: String
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
    
    var role: AccountRole {
        get {
            AccountRole(rawValue: roleRawValue) ?? .user
        }
        set {
            roleRawValue = newValue.rawValue
        }
    }
    
    var password: String {
        get {
            guard let encryptedPassword else { return "" }
            do {
                return try SecurityUtils.decryptUserData(encryptedPassword)
            } catch {
                print("Error decrypting password: \(error)")
                return ""
            }
        }
        set {
            do {
                encryptedPassword = try SecurityUtils.encryptUserData(newValue)
            } catch {
                print("Error encrypting password: \(error)")
            }
        }
    }

    init(
        id: UUID = UUID(),
        username: String,
        email: String,
        password: String,
        role: AccountRole = .user,
        notificationsEnabled: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.roleRawValue = role.rawValue
        self.notificationsEnabled = notificationsEnabled
        self.createdAt = createdAt
        
        // Шифруем при инициализации
        do {
            self.encryptedUsername = try SecurityUtils.encryptUserData(username)
            self.encryptedEmail = try SecurityUtils.encryptUserData(email)
            self.encryptedPassword = try SecurityUtils.encryptUserData(password)
        } catch {
            print("Error encrypting user data during init: \(error)")
            self.encryptedUsername = Data()
            self.encryptedEmail = Data()
            self.encryptedPassword = nil
        }
    }
}

extension UserProfile {
    static let sample = UserProfile(username: "Aslan", email: "user@example.com", password: "Pass123")
}
