import Foundation
import Combine

enum AccountRole: String, Codable, CaseIterable {
    case admin
    case user
    case guest
    
    var title: String {
        switch self {
        case .admin:
            return "Админ"
        case .user:
            return "Пользователь"
        case .guest:
            return "Гость"
        }
    }
    
    var isAuthenticated: Bool {
        self != .guest
    }
}

enum AppFeature {
    case payments
    case cards
    case categoriesManagement
    case profileEditing
}

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    private let tokenKey = "authToken"
    private let currentProfileIDKey = "currentProfileID"
    private let pinKey = "userPin"
    private let roleKey = "accountRole"
    private let inactivityTimeout: TimeInterval = 300
    
    private var inactivityTimer: Timer?
    private var pendingRole: AccountRole?
    
    @Published private(set) var currentRole: AccountRole
    @Published private(set) var currentProfileID: UUID?
    
    private init() {
        let storedRole = Self.loadStoredRole(forKey: roleKey)
        currentRole = storedRole
        currentProfileID = Self.loadStoredProfileID(forKey: currentProfileIDKey)
        
        if storedRole.isAuthenticated {
            startInactivityTimer()
        }
    }
    
    func login(username: String, password: String) async throws -> Bool {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        if (username == "test" || username == "admin") && password == "password" {
            pendingRole = resolveRole(for: username)
            return true
        }
        
        return false
    }
    
    func verify2FA(pin: String) -> Bool {
        if let storedPin = UserDefaults.standard.string(forKey: pinKey), storedPin == pin {
            saveToken("authenticatedToken")
            completeAuthentication(with: pendingRole ?? .user)
            return true
        }
        
        return false
    }
    
    func setPin(_ pin: String) {
        UserDefaults.standard.set(pin, forKey: pinKey)
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        pendingRole = nil
        clearCurrentProfileID()
        persistRole(.guest)
        currentRole = .guest
        stopInactivityTimer()
    }
    
    func continueAsGuest() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        pendingRole = nil
        clearCurrentProfileID()
        persistRole(.guest)
        currentRole = .guest
        stopInactivityTimer()
    }
    
    func getToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    func authenticateWithBiometrics(as role: AccountRole = .user) {
        saveToken("biometricToken")
        completeAuthentication(with: role)
    }
    
    func signIn(as role: AccountRole, profileID: UUID? = nil, token: String = "authenticatedToken") {
        saveToken(token)
        if let profileID {
            persistCurrentProfileID(profileID)
        } else {
            clearCurrentProfileID()
        }
        completeAuthentication(with: role)
    }
    
    func isAuthenticated() -> Bool {
        currentRole.isAuthenticated && getToken() != nil
    }
    
    func hasAccess(to feature: AppFeature) -> Bool {
        switch (currentRole, feature) {
        case (.admin, _):
            return true
        case (.user, .payments), (.user, .cards), (.user, .profileEditing):
            return true
        case (.guest, _), (.user, .categoriesManagement):
            return false
        }
    }
    
    func resetInactivityTimer() {
        guard currentRole.isAuthenticated else { return }
        stopInactivityTimer()
        startInactivityTimer()
    }
    
    private func completeAuthentication(with role: AccountRole) {
        pendingRole = nil
        persistRole(role)
        currentRole = role
        startInactivityTimer()
    }
    
    private func persistRole(_ role: AccountRole) {
        UserDefaults.standard.set(role.rawValue, forKey: roleKey)
    }
    
    private func persistCurrentProfileID(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: currentProfileIDKey)
        currentProfileID = id
    }
    
    private func clearCurrentProfileID() {
        UserDefaults.standard.removeObject(forKey: currentProfileIDKey)
        currentProfileID = nil
    }
    
    private func resolveRole(for username: String) -> AccountRole {
        username.lowercased() == "admin" ? .admin : .user
    }
    
    private static func loadStoredRole(forKey key: String) -> AccountRole {
        guard
            let rawValue = UserDefaults.standard.string(forKey: key),
            let role = AccountRole(rawValue: rawValue)
        else {
            return .guest
        }
        
        return role
    }
    
    private static func loadStoredProfileID(forKey key: String) -> UUID? {
        guard let rawValue = UserDefaults.standard.string(forKey: key) else {
            return nil
        }
        return UUID(uuidString: rawValue)
    }
    
    private func startInactivityTimer() {
        stopInactivityTimer()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: inactivityTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.logout()
            }
        }
    }
    
    private func stopInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }
}
