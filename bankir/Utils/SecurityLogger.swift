import Foundation
import OSLog

// Логирование подозрительного ввода для аудита
class SecurityLogger {
    private static let logger = Logger(subsystem: "com.bankir.security", category: "input")
    
    static func logSuspiciousInput(_ input: String, type: String, reason: String) {
        logger.warning("Suspicious input detected: \(input.prefix(50))... Type: \(type), Reason: \(reason)")
    }
    
    static func logRateLimitExceeded(userId: String? = nil, action: String) {
        logger.warning("Rate limit exceeded for action: \(action), User: \(userId ?? "unknown")")
    }
    
    static func logValidationFailure(_ input: String, type: String) {
        logger.info("Validation failed for input: \(input.prefix(20))..., Type: \(type)")
    }
}