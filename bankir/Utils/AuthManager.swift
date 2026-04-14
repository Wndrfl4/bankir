import Foundation

// Менеджер аутентификации
class AuthManager {
    static let shared = AuthManager()
    private let tokenKey = "authToken"
    private let pinKey = "userPin"
    private var inactivityTimer: Timer?
    private let inactivityTimeout: TimeInterval = 300 // 5 минут
    
    private init() {
        startInactivityTimer()
    }
    
    // Логин (пример с mock)
    func login(username: String, password: String) async throws -> Bool {
        // Mock
        try await Task.sleep(nanoseconds: 500_000_000)
        if username == "test" && password == "password" {
            // После успешного логина, запросить 2FA
            return true // Вернуть true, но затем проверить 2FA
        }
        return false
    }
    
    // Проверить 2FA (PIN)
    func verify2FA(pin: String) -> Bool {
        if let storedPin = UserDefaults.standard.string(forKey: pinKey), storedPin == pin {
            saveToken("authenticatedToken")
            startInactivityTimer()
            return true
        }
        return false
    }
    
    // Установить PIN для 2FA
    func setPin(_ pin: String) {
        UserDefaults.standard.set(pin, forKey: pinKey)
    }
    
    // Логаут
    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        stopInactivityTimer()
    }
    
    // Получить токен
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    // Проверить, аутентифицирован ли пользователь
    func isAuthenticated() -> Bool {
        return getToken() != nil
    }
    
    // Сброс таймера бездействия
    func resetInactivityTimer() {
        stopInactivityTimer()
        startInactivityTimer()
    }
    
    private func startInactivityTimer() {
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: inactivityTimeout, repeats: false) { [weak self] _ in
            self?.logout()
        }
    }
    
    private func stopInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }
}