import Foundation

// Структура для ответов API
struct TransferResponse: Codable {
    let success: Bool
    let message: String?
}

struct TopUpResponse: Codable {
    let success: Bool
}

struct PayBillResponse: Codable {
    let success: Bool
}

// Простая абстракция над платежами. Теперь с реальными запросами (mock для примера)
protocol PaymentsAPI {
    func transfer(fromCard: String, toCard: String, amount: Decimal, note: String) async throws
    func topUp(provider: String, phone: String, amount: Decimal) async throws
    func payBill(category: String, account: String, amount: Decimal) async throws
}

enum PaymentsError: Error {
    case limitExceeded
    case server
    case network(Error)
}

final class DefaultPaymentsAPI: PaymentsAPI {
    static let shared = DefaultPaymentsAPI()
    private let baseURL = URL(string: "https://api.bankir.com")! // Заменить на реальный URL
    
    private init() {}
    
    func transfer(fromCard: String, toCard: String, amount: Decimal, note: String) async throws {
        // Валидация перед отправкой
        guard fromCard.count == 16, toCard.count == 16, amount > 0 else {
            throw PaymentsError.server
        }
        
        // В реальном коде: отправить запрос
        // let response: TransferResponse = try await NetworkManager.shared.performRequest(
        //     url: baseURL.appendingPathComponent("/transfer"),
        //     method: "POST",
        //     body: JSONEncoder().encode(["fromCard": fromCard, "toCard": toCard, "amount": amount, "note": note])
        // )
        
        // Mock для примера
        try await Task.sleep(nanoseconds: 1_000_000_000)
        if amount > 1_000_000 {
            throw PaymentsError.limitExceeded
        }
        // Предполагаем успех
    }
    
    func topUp(provider: String, phone: String, amount: Decimal) async throws {
        // Аналогично
        try await Task.sleep(nanoseconds: 800_000_000)
        if phone.count < 11 {
            throw PaymentsError.server
        }
    }
    
    func payBill(category: String, account: String, amount: Decimal) async throws {
        // Аналогично
        try await Task.sleep(nanoseconds: 1_100_000_000)
        if amount <= 0 {
            throw PaymentsError.server
        }
    }
}
