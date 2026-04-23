import Foundation
import Combine

private struct AuthLoginRequest: Encodable {
    let username: String
    let password: String
}

private struct AuthRegisterRequest: Encodable {
    let username: String
    let email: String
    let password: String
}

private struct AuthLoginResponse: Decodable {
    let userId: String
    let role: String
    let accessToken: String
    let refreshToken: String
}

private struct AuthRegisterResponse: Decodable {
    let userId: String
    let accessToken: String
    let refreshToken: String
}

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
    private let refreshTokenKey = "refreshToken"
    private let currentProfileIDKey = "currentProfileID"
    private let currentUserIDKey = "currentUserID"
    private let pinKey = "userPin"
    private let roleKey = "accountRole"
    private let inactivityTimeout: TimeInterval = 300
    
    private var inactivityTimer: Timer?
    private var pendingRole: AccountRole?
    private var pendingUserID: String?
    private var pendingAccessToken: String?
    private var pendingRefreshToken: String?
    
    @Published private(set) var currentRole: AccountRole
    @Published private(set) var currentProfileID: UUID?
    @Published private(set) var currentUserID: String?
    @Published private(set) var isAuthenticated = false
    
    private init() {
        let storedRole = Self.loadStoredRole(forKey: roleKey)
        let storedUserID = UserDefaults.standard.string(forKey: currentUserIDKey)
        currentRole = storedRole
        currentProfileID = Self.loadStoredProfileID(forKey: currentProfileIDKey) ?? storedUserID.flatMap(UUID.init(uuidString:))
        currentUserID = storedUserID
        isAuthenticated = storedRole.isAuthenticated && UserDefaults.standard.string(forKey: tokenKey) != nil
        
        if storedRole.isAuthenticated {
            startInactivityTimer()
        }
    }
    
    func login(username: String, password: String) async throws -> Bool {
        let response: AuthLoginResponse = try await NetworkManager.shared.performRequest(
            url: NetworkManager.shared.endpoint("auth/login"),
            body: AuthLoginRequest(username: username, password: password)
        )
        
        pendingRole = Self.mapRole(response.role)
        pendingUserID = response.userId
        pendingAccessToken = response.accessToken
        pendingRefreshToken = response.refreshToken
        return true
    }
    
    func register(username: String, email: String, password: String) async throws {
        let response: AuthRegisterResponse = try await NetworkManager.shared.performRequest(
            url: NetworkManager.shared.endpoint("auth/register"),
            body: AuthRegisterRequest(username: username, email: email, password: password)
        )
        
        signIn(
            as: .user,
            userID: response.userId,
            token: response.accessToken,
            refreshToken: response.refreshToken
        )
    }
    
    func verify2FA(pin: String) -> Bool {
        guard let storedPin = UserDefaults.standard.string(forKey: pinKey), storedPin == pin else {
            return false
        }
        
        guard let pendingAccessToken else {
            return false
        }
        
        saveToken(pendingAccessToken)
        if let pendingRefreshToken {
            saveRefreshToken(pendingRefreshToken)
        }
        if let pendingUserID {
            persistCurrentUserID(pendingUserID)
            if let derivedProfileID = UUID(uuidString: pendingUserID) {
                persistCurrentProfileID(derivedProfileID)
            }
        }
        
        completeAuthentication(with: pendingRole ?? .user)
        clearPendingAuthentication()
        return true
    }
    
    func hasPIN() -> Bool {
        UserDefaults.standard.string(forKey: pinKey) != nil
    }
    
    func completePendingAuthenticationAfterPINSetup() {
        guard let pendingAccessToken else { return }
        
        saveToken(pendingAccessToken)
        if let pendingRefreshToken {
            saveRefreshToken(pendingRefreshToken)
        }
        if let pendingUserID {
            persistCurrentUserID(pendingUserID)
            if let derivedProfileID = UUID(uuidString: pendingUserID) {
                persistCurrentProfileID(derivedProfileID)
            }
        }
        
        completeAuthentication(with: pendingRole ?? .user)
        clearPendingAuthentication()
    }
    
    func setPin(_ pin: String) {
        UserDefaults.standard.set(pin, forKey: pinKey)
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        clearPendingAuthentication()
        clearCurrentProfileID()
        clearCurrentUserID()
        persistRole(.guest)
        currentRole = .guest
        isAuthenticated = false
        stopInactivityTimer()
    }
    
    func continueAsGuest() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        clearPendingAuthentication()
        clearCurrentProfileID()
        clearCurrentUserID()
        persistRole(.guest)
        currentRole = .guest
        isAuthenticated = false
        stopInactivityTimer()
    }
    
    func getToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    func getRefreshToken() -> String? {
        UserDefaults.standard.string(forKey: refreshTokenKey)
    }
    
    func saveRefreshToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: refreshTokenKey)
    }
    
    func authenticateWithBiometrics(as role: AccountRole = .user) {
        guard getToken() != nil else { return }
        completeAuthentication(with: role)
    }
    
    func signIn(
        as role: AccountRole,
        profileID: UUID? = nil,
        userID: String? = nil,
        token: String = "authenticatedToken",
        refreshToken: String? = nil
    ) {
        saveToken(token)
        if let refreshToken {
            saveRefreshToken(refreshToken)
        }
        if let profileID {
            persistCurrentProfileID(profileID)
        } else if let userID, let derivedProfileID = UUID(uuidString: userID) {
            persistCurrentProfileID(derivedProfileID)
        } else {
            clearCurrentProfileID()
        }
        if let userID {
            persistCurrentUserID(userID)
        } else {
            clearCurrentUserID()
        }
        completeAuthentication(with: role)
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
    
    func authenticatedRequestUserID() throws -> String {
        guard let currentUserID else {
            throw NetworkError.server(statusCode: 401, message: "User session is missing.")
        }
        
        return currentUserID
    }
    
    private func completeAuthentication(with role: AccountRole) {
        pendingRole = nil
        persistRole(role)
        currentRole = role
        isAuthenticated = true
        startInactivityTimer()
    }
    
    private func persistRole(_ role: AccountRole) {
        UserDefaults.standard.set(role.rawValue, forKey: roleKey)
    }
    
    private func persistCurrentUserID(_ id: String) {
        UserDefaults.standard.set(id, forKey: currentUserIDKey)
        currentUserID = id
    }
    
    private func clearCurrentUserID() {
        UserDefaults.standard.removeObject(forKey: currentUserIDKey)
        currentUserID = nil
    }
    
    private func persistCurrentProfileID(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: currentProfileIDKey)
        currentProfileID = id
    }
    
    private func clearCurrentProfileID() {
        UserDefaults.standard.removeObject(forKey: currentProfileIDKey)
        currentProfileID = nil
    }
    
    private func clearPendingAuthentication() {
        pendingRole = nil
        pendingUserID = nil
        pendingAccessToken = nil
        pendingRefreshToken = nil
    }
    
    private static func mapRole(_ rawRole: String) -> AccountRole {
        switch rawRole.lowercased() {
        case "admin":
            return .admin
        default:
            return .user
        }
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
