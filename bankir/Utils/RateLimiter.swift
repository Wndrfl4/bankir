import Foundation

// Rate limiting для предотвращения спама и DoS атак
class RateLimiter {
    private var attempts: [Date] = []
    private let maxAttempts: Int
    private let timeWindow: TimeInterval
    
    init(maxAttempts: Int = 5, timeWindow: TimeInterval = 60) { // 5 попыток в минуту
        self.maxAttempts = maxAttempts
        self.timeWindow = timeWindow
    }
    
    func canAttempt() -> Bool {
        let now = Date()
        // Удалить старые попытки
        attempts = attempts.filter { now.timeIntervalSince($0) < timeWindow }
        let can = attempts.count < maxAttempts
        if !can {
            SecurityLogger.logRateLimitExceeded(action: "Rate limited action")
        }
        return can
    }
    
    func recordAttempt() {
        attempts.append(Date())
    }
    
    func reset() {
        attempts.removeAll()
    }
    
    var remainingAttempts: Int {
        let now = Date()
        attempts = attempts.filter { now.timeIntervalSince($0) < timeWindow }
        return max(0, maxAttempts - attempts.count)
    }
}