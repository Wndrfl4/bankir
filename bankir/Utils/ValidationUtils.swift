import Foundation

// Утилиты для валидации ввода
class ValidationUtils {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func isValidCardNumber(_ card: String) -> Bool {
        let cleaned = card.replacingOccurrences(of: " ", with: "")
        return cleaned.count == 16 && cleaned.allSatisfy { $0.isNumber }
    }
    
    static func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = "^\\+7 \\([0-9]{3}\\) [0-9]{3}-[0-9]{2}-[0-9]{2}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
    
    static func isValidAmount(_ amount: String) -> Bool {
        if let decimal = Decimal(string: amount), decimal > 0 {
            return true
        }
        return false
    }
    
    static func isValidUsername(_ username: String) -> Bool {
        let sanitized = InputSanitization.alphanumericOnly(username)
        return sanitized.count >= 3 && sanitized.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6 && !password.contains(where: { $0.isWhitespace }) && password.rangeOfCharacter(from: .letters) != nil && password.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    // Валидация IBAN (упрощенная)
    static func isValidIBAN(_ iban: String) -> Bool {
        let sanitized = InputSanitization.sanitizeBankCode(iban)
        return sanitized.count >= 15 && sanitized.count <= 34 && sanitized.allSatisfy { $0.isLetter || $0.isNumber }
    }
    
    // Валидация SWIFT/BIC кода
    static func isValidSWIFT(_ swift: String) -> Bool {
        let sanitized = InputSanitization.sanitizeBankCode(swift)
        return sanitized.count == 8 || sanitized.count == 11
    }
    
    // Валидация CVV
    static func isValidCVV(_ cvv: String) -> Bool {
        return cvv.count == 3 && cvv.allSatisfy { $0.isNumber }
    }
    
    // Санитизированная версия
    static func sanitizeAndValidateEmail(_ email: String) -> (isValid: Bool, sanitized: String) {
        let sanitized = InputSanitization.sanitizeForAPI(email, maxLength: 254)
        let isValid = isValidEmail(sanitized)
        if !isValid {
            SecurityLogger.logValidationFailure(email, type: "Email")
        }
        return (isValid, sanitized)
    }
}