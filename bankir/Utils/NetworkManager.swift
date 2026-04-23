import Foundation

private struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

private struct RefreshTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}

struct APIAccount: Decodable, Identifiable {
    let id: String
    let iban: String
    let currency: String
    let balance: Decimal
    let isPrimary: Bool
}

struct APIUserProfile: Decodable {
    let id: String
    let username: String
    let email: String
    let role: String
    let accounts: [APIAccount]
    let createdAt: Date
}

struct APITransaction: Decodable, Identifiable {
    let id: String
    let type: String
    let status: String
    let amount: Decimal
    let currency: String
    let note: String?
    let provider: String?
    let billCategory: String?
    let sourceUserId: String?
    let destinationUserId: String?
    let sourceAccountId: String?
    let destinationAccountId: String?
    let createdAt: Date
}

private struct UpdateProfileRequest: Encodable {
    let username: String
    let email: String
}

private struct ChangePasswordRequest: Encodable {
    let currentPassword: String
    let newPassword: String
}

private struct ChangePasswordResponse: Decodable {
    let success: Bool
}

struct APIConfig {
    private static let infoPlistKey = "BANKIR_API_BASE_URL"
    private static let userDefaultsOverrideKey = "apiBaseURLOverride"
    
    static let baseURL: URL = {
        if let override = UserDefaults.standard.string(forKey: userDefaultsOverrideKey),
           let url = URL(string: override),
           !override.isEmpty {
            return url
        }
        
        if let configured = Bundle.main.object(forInfoDictionaryKey: infoPlistKey) as? String,
           let url = URL(string: configured),
           !configured.isEmpty {
            return url
        }
        
        #if targetEnvironment(simulator)
        return URL(string: "http://127.0.0.1:3000/api")!
        #else
        return URL(string: "http://MacBook-Air-Aslan.local:3000/api")!
        #endif
    }()
}

enum NetworkError: LocalizedError {
    case invalidResponse
    case server(statusCode: Int, message: String?)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response."
        case .server(_, let message):
            return message ?? "Server request failed."
        }
    }
}

private struct APIErrorResponse: Decodable {
    let message: APIErrorMessage
    
    enum APIErrorMessage: Decodable {
        case text(String)
        case list([String])
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let text = try? container.decode(String.self) {
                self = .text(text)
            } else {
                self = .list(try container.decode([String].self))
            }
        }
        
        var joinedMessage: String {
            switch self {
            case .text(let text):
                return text
            case .list(let list):
                return list.joined(separator: "\n")
            }
        }
    }
}

struct EmptyResponse: Decodable {}

actor TokenRefreshCoordinator {
    private var refreshTask: Task<String, Error>?
    
    func refresh(using operation: @escaping @Sendable () async throws -> String) async throws -> String {
        if let refreshTask {
            return try await refreshTask.value
        }
        
        let task = Task {
            try await operation()
        }
        refreshTask = task
        
        defer { refreshTask = nil }
        return try await task.value
    }
}

// Менеджер для сетевых запросов с безопасностью
class NetworkManager {
    static let shared = NetworkManager()
    private let session: URLSession
    private let decoder: JSONDecoder
    private let refreshCoordinator = TokenRefreshCoordinator()
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        
        let delegate = CertificatePinningDelegate()
        session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }
    
    func endpoint(_ path: String) -> URL {
        APIConfig.baseURL.appendingPathComponent(path)
    }
    
    func performRequest<T: Decodable>(
        url: URL,
        method: String = "GET",
        body: Data? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        try await performRequest(
            url: url,
            method: method,
            body: body,
            headers: headers,
            includeAuthorization: true,
            retryOnUnauthorized: true
        )
    }
    
    private func performRequest<T: Decodable>(
        url: URL,
        method: String,
        body: Data?,
        headers: [String: String],
        includeAuthorization: Bool,
        retryOnUnauthorized: Bool
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if includeAuthorization, let token = await MainActor.run(body: {
            AuthManager.shared.getToken()
        }) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401, retryOnUnauthorized, includeAuthorization {
                do {
                    _ = try await refreshAccessToken()
                    return try await performRequest(
                        url: url,
                        method: method,
                        body: body,
                        headers: headers,
                        includeAuthorization: true,
                        retryOnUnauthorized: false
                    )
                } catch {
                    await MainActor.run {
                        AuthManager.shared.logout()
                    }
                    throw error
                }
            }
            
            let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw NetworkError.server(statusCode: httpResponse.statusCode, message: apiError?.message.joinedMessage)
        }
        
        return try decoder.decode(T.self, from: data)
    }
    
    func performRequest<T: Decodable, Body: Encodable>(
        url: URL,
        method: String = "POST",
        body: Body,
        headers: [String: String] = [:]
    ) async throws -> T {
        let bodyData = try JSONEncoder().encode(body)
        return try await performRequest(url: url, method: method, body: bodyData, headers: headers)
    }
    
    func fetchCurrentUser() async throws -> APIUserProfile {
        try await performRequest(url: endpoint("users/me"))
    }
    
    func updateCurrentUser(username: String, email: String) async throws -> APIUserProfile {
        try await performRequest(
            url: endpoint("users/me"),
            method: "PATCH",
            body: UpdateProfileRequest(username: username, email: email)
        )
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        let _: ChangePasswordResponse = try await performRequest(
            url: endpoint("users/change-password"),
            body: ChangePasswordRequest(currentPassword: currentPassword, newPassword: newPassword)
        )
    }
    
    func fetchTransactions() async throws -> [APITransaction] {
        try await performRequest(url: endpoint("transactions"))
    }
    
    private func refreshAccessToken() async throws -> String {
        try await refreshCoordinator.refresh {
            let refreshToken = try await MainActor.run {
                guard let token = AuthManager.shared.getRefreshToken(), !token.isEmpty else {
                    throw NetworkError.server(statusCode: 401, message: "Refresh token is missing.")
                }
                return token
            }
            
            let bodyData = try JSONEncoder().encode(RefreshTokenRequest(refreshToken: refreshToken))
            let response: RefreshTokenResponse = try await self.performRequest(
                url: self.endpoint("auth/refresh"),
                method: "POST",
                body: bodyData,
                headers: [:],
                includeAuthorization: false,
                retryOnUnauthorized: false
            )
            
            await MainActor.run {
                AuthManager.shared.saveToken(response.accessToken)
                AuthManager.shared.saveRefreshToken(response.refreshToken)
            }
            
            return response.accessToken
        }
    }
}

// Certificate Pinning Delegate
class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
