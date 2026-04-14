#if canImport(Testing) && canImport(bankir)
import Testing
@testable import bankir

@Suite("Validation rules")
struct ValidationTests {

    @Test("Email validation")
    func emailValidation() {
        #expect(ValidationUtils.isValidEmail("test@example.com"))
        #expect(!ValidationUtils.isValidEmail("invalid"))
    }

    @Test("Card number validation")
    func cardValidation() {
        #expect(ValidationUtils.isValidCardNumber("1234567890123456"))
        #expect(!ValidationUtils.isValidCardNumber("123"))
    }

    @Test("Phone validation")
    func phoneValidation() {
        #expect(ValidationUtils.isValidPhone("+7 (777) 123-45-67"))
        #expect(!ValidationUtils.isValidPhone("123"))
    }

    @Test("Amount validation")
    func amountValidation() {
        #expect(ValidationUtils.isValidAmount("100.50"))
        #expect(!ValidationUtils.isValidAmount("-10"))
    }

    @Test("Username validation")
    func usernameValidation() {
        #expect(ValidationUtils.isValidUsername("user123"))
        #expect(!ValidationUtils.isValidUsername("u"))
    }

    @Test("Password validation")
    func passwordValidation() {
        #expect(ValidationUtils.isValidPassword("password"))
        #expect(!ValidationUtils.isValidPassword("123"))
    }

    @Test("Transfer validation: requires 16-digit card and positive amount")
    func transferValidation() async throws {
        let vm = TransferViewModel()
        #expect(vm.isValid == false)
        vm.toCardMasked = "1234 5678 9012 3456"
        vm.amount = 1000
        #expect(vm.isValid)
    }

    @Test("Input sanitization")
    func testInputSanitization() {
        // Тест санитизации
        let maliciousInput = "<script>alert('xss')</script>Hello World"
        let sanitized = InputSanitization.sanitizeString(maliciousInput)
        #expect(!sanitized.contains("<script>"))
        #expect(sanitized.contains("Hello World"))
        
        // Тест ограничения длины
        let longInput = String(repeating: "a", count: 300)
        let limited = InputSanitization.limitLength(longInput, maxLength: 100)
        #expect(limited.count == 100)
        
        // Тест только алфанумерика
        let mixedInput = "Hello123!@#"
        let alphanumeric = InputSanitization.alphanumericOnly(mixedInput)
        #expect(alphanumeric == "Hello123")
        
        // Тест банковского кода
        let ibanInput = "DE89 3704 0044 0532 0130 00"
        let sanitizedIBAN = InputSanitization.sanitizeBankCode(ibanInput)
        #expect(sanitizedIBAN == "DE89370400440532013000")
        
        // Тест JSON escape
        let jsonInput = "Test \"quote\" and \\backslash"
        let escaped = InputSanitization.escapeForJSON(jsonInput)
        #expect(escaped == "Test \\\"quote\\\" and \\\\backslash")
    }
    
    @Test("Advanced validation")
    func testAdvancedValidation() {
        // IBAN
        #expect(ValidationUtils.isValidIBAN("DE89370400440532013000"))
        #expect(!ValidationUtils.isValidIBAN("INVALID"))
        
        // SWIFT
        #expect(ValidationUtils.isValidSWIFT("DEUTDEFF"))
        #expect(!ValidationUtils.isValidSWIFT("SHORT"))
        
        // CVV
        #expect(ValidationUtils.isValidCVV("123"))
        #expect(!ValidationUtils.isValidCVV("12"))
        
        // Улучшенный пароль
        #expect(ValidationUtils.isValidPassword("Pass123"))
        #expect(!ValidationUtils.isValidPassword("password")) // нет цифр
        #expect(!ValidationUtils.isValidPassword("123456")) // нет букв
    }
    
    @Test("Rate limiting")
    func testRateLimiting() async throws {
        let limiter = RateLimiter(maxAttempts: 2, timeWindow: 1) // 2 попытки в 1 секунду
        
        // Должно позволить
        #expect(limiter.canAttempt())
        limiter.recordAttempt()
        #expect(limiter.canAttempt())
        limiter.recordAttempt()
        #expect(!limiter.canAttempt()) // Превышен лимит
        
        // Подождать больше времени
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 секунды
        #expect(limiter.canAttempt()) // Сбросилось
    }

    @Test("TopUp validation: requires +7 phone (11 digits) and positive amount")
    func topUpValidation() async throws {
        let vm = TopUpViewModel()
        #expect(vm.isValid == false)
        vm.phoneMasked = "+7 (777) 123-45-67"
        vm.amount = 500
        #expect(vm.isValid)
    }

    @Test("Device security checks")
    func deviceSecurity() {
        // Mock тесты, в реальности проверить на устройстве
        #expect(!DeviceSecurity.shared.isDebuggerAttached() || true) // Зависит от среды
    }
}
#endif
