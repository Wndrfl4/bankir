import Foundation
import CryptoKit
import Security

// Утилиты для шифрования данных с использованием AES-GCM и Keychain для хранения ключа
class SecurityUtils {
    private static let userKeyTag = "com.bankir.userEncryptionKey"
    private static let transactionKeyTag = "com.bankir.transactionEncryptionKey"
    
    // Получить или создать ключ шифрования для пользователей
    private static func getUserEncryptionKey() throws -> SymmetricKey {
        try getOrCreateKey(tag: userKeyTag)
    }
    
    // Получить или создать ключ шифрования для транзакций
    private static func getTransactionEncryptionKey() throws -> SymmetricKey {
        try getOrCreateKey(tag: transactionKeyTag)
    }
    
    private static func getOrCreateKey(tag: String) throws -> SymmetricKey {
        // Попытаться загрузить ключ из Keychain
        if let keyData = try loadKeyFromKeychain(tag: tag) {
            return SymmetricKey(data: keyData)
        } else {
            // Создать новый ключ и сохранить
            let key = SymmetricKey(size: .bits256)
            try saveKeyToKeychain(key, tag: tag)
            return key
        }
    }
    
    private static func loadKeyFromKeychain(tag: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            return item as? Data
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw NSError(domain: "KeychainError", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to load key for tag \(tag)"])
        }
    }
    
    private static func saveKeyToKeychain(_ key: SymmetricKey, tag: String) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw NSError(domain: "KeychainError", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to save key for tag \(tag)"])
        }
    }
    
    // Шифрование строки для пользователей
    static func encryptUserData(_ string: String) throws -> Data {
        let key = try getUserEncryptionKey()
        return try encryptData(string, using: key)
    }
    
    // Дешифрование для пользователей
    static func decryptUserData(_ data: Data) throws -> String {
        let key = try getUserEncryptionKey()
        return try decryptData(data, using: key)
    }
    
    // Шифрование для транзакций
    static func encryptTransactionData(_ string: String) throws -> Data {
        let key = try getTransactionEncryptionKey()
        return try encryptData(string, using: key)
    }
    
    // Дешифрование для транзакций
    static func decryptTransactionData(_ data: Data) throws -> String {
        let key = try getTransactionEncryptionKey()
        return try decryptData(data, using: key)
    }
    
    private static func encryptData(_ string: String, using key: SymmetricKey) throws -> Data {
        let data = string.data(using: .utf8)!
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    private static func decryptData(_ data: Data, using key: SymmetricKey) throws -> String {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return String(data: decryptedData, encoding: .utf8)!
    }
}