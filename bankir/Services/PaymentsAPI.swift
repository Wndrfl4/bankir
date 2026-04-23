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

private struct TransferRequest: Encodable {
    let fromCard: String
    let toCard: String
    let amount: Decimal
    let note: String
}

private struct TopUpRequest: Encodable {
    let provider: String
    let phone: String
    let amount: Decimal
}

private struct PayBillRequest: Encodable {
    let category: String
    let account: String
    let amount: Decimal
}

final class DefaultPaymentsAPI: PaymentsAPI {
    static let shared = DefaultPaymentsAPI()
    
    private init() {}
    
    func transfer(fromCard: String, toCard: String, amount: Decimal, note: String) async throws {
        guard fromCard.count == 16, toCard.count == 16, amount > 0 else {
            throw PaymentsError.server
        }
        
        do {
            let _: TransferResponse = try await NetworkManager.shared.performRequest(
                url: NetworkManager.shared.endpoint("payments/transfer"),
                body: TransferRequest(
                    fromCard: fromCard,
                    toCard: toCard,
                    amount: amount,
                    note: note
                )
            )
        } catch let error as PaymentsError {
            throw error
        } catch {
            throw PaymentsError.network(error)
        }
    }
    
    func topUp(provider: String, phone: String, amount: Decimal) async throws {
        guard phone.count >= 11, amount > 0 else {
            throw PaymentsError.server
        }
        
        do {
            let _: TopUpResponse = try await NetworkManager.shared.performRequest(
                url: NetworkManager.shared.endpoint("payments/top-up"),
                body: TopUpRequest(
                    provider: provider,
                    phone: phone,
                    amount: amount
                )
            )
        } catch {
            throw PaymentsError.network(error)
        }
    }
    
    func payBill(category: String, account: String, amount: Decimal) async throws {
        if amount <= 0 {
            throw PaymentsError.server
        }
        
        do {
            let _: PayBillResponse = try await NetworkManager.shared.performRequest(
                url: NetworkManager.shared.endpoint("payments/bills"),
                body: PayBillRequest(
                    category: category,
                    account: account,
                    amount: amount
                )
            )
        } catch {
            throw PaymentsError.network(error)
        }
    }
}
