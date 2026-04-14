import Foundation

// Санитизация ввода и защита от инъекций
class InputSanitization {
    // Удаление потенциально опасных символов
    static func sanitizeString(_ input: String) -> String {
        // Удалить скрипты, HTML и т.д.
        var sanitized = input
        // Удалить <script> теги
        sanitized = sanitized.replacingOccurrences(of: "<script[^>]*>.*?</script>", with: "", options: .regularExpression)
        // Удалить HTML теги
        sanitized = sanitized.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        // Удалить SQL ключевые слова (базовая защита)
        let sqlKeywords = ["SELECT", "INSERT", "UPDATE", "DELETE", "DROP", "UNION", "EXEC", "ALTER", "CREATE", "TRUNCATE"]
        for keyword in sqlKeywords {
            sanitized = sanitized.replacingOccurrences(of: keyword, with: "", options: .caseInsensitive)
        }
        // Удалить специальные символы для JSON инъекций
        sanitized = sanitized.replacingOccurrences(of: "[\"{}]", with: "", options: .regularExpression)
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Ограничение длины
    static func limitLength(_ input: String, maxLength: Int) -> String {
        return String(input.prefix(maxLength))
    }
    
    // Только алфанумерика
    static func alphanumericOnly(_ input: String) -> String {
        return input.filter { $0.isLetter || $0.isNumber || $0.isWhitespace }
    }
    
    // Только алфанумерика без пробелов
    static func alphanumericNoSpaces(_ input: String) -> String {
        return input.filter { $0.isLetter || $0.isNumber }
    }
    
    // Для сумм: только числа и точка
    static func numericOnly(_ input: String) -> String {
        return input.filter { $0.isNumber || $0 == "." }
    }
    
    // Для URL: базовая санитизация
    static func sanitizeURL(_ input: String) -> String {
        var sanitized = sanitizeString(input)
        // Удалить javascript: и data: схемы
        sanitized = sanitized.replacingOccurrences(of: "^(javascript|data):", with: "", options: .regularExpression)
        return sanitized
    }
    
    // Escape для JSON
    static func escapeForJSON(_ input: String) -> String {
        return input.replacingOccurrences(of: "\"", with: "\\\"")
                     .replacingOccurrences(of: "\\", with: "\\\\")
                     .replacingOccurrences(of: "\n", with: "\\n")
                     .replacingOccurrences(of: "\r", with: "\\r")
                     .replacingOccurrences(of: "\t", with: "\\t")
    }
    
    // Комплексная санитизация для API
    static func sanitizeForAPI(_ input: String, maxLength: Int = 255) -> String {
        let original = input
        var sanitized = sanitizeString(input)
        sanitized = limitLength(sanitized, maxLength: maxLength)
        
        // Логировать если было изменение
        if sanitized != original {
            SecurityLogger.logSuspiciousInput(original, type: "API Input", reason: "Sanitized content")
        }
        
        return sanitized
    }
    
    // Для банковских кодов (IBAN, SWIFT)
    static func sanitizeBankCode(_ input: String) -> String {
        return alphanumericNoSpaces(input.uppercased())
    }
}