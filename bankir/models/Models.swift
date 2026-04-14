import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var encryptedName: Data
    var createdAt: Date
    @Relationship(inverse: \Transaction.category)
    var transactions: [Transaction]

    var name: String {
        get {
            do {
                return try SecurityUtils.decryptTransactionData(encryptedName) // Используем transaction key для простоты
            } catch {
                print("Error decrypting category name: \(error)")
                return ""
            }
        }
        set {
            do {
                encryptedName = try SecurityUtils.encryptTransactionData(newValue)
            } catch {
                print("Error encrypting category name: \(error)")
            }
        }
    }

    init(id: UUID = UUID(), name: String, createdAt: Date = .now, transactions: [Transaction] = []) {
        self.id = id
        self.createdAt = createdAt
        self.transactions = transactions
        
        do {
            self.encryptedName = try SecurityUtils.encryptTransactionData(name)
        } catch {
            print("Error encrypting category name during init: \(error)")
            self.encryptedName = Data()
        }
    }

    var totalAmount: Decimal {
        transactions.reduce(0) { $0 + $1.amount }
    }
}

@Model
final class Transaction {
    var id: UUID
    var encryptedAmount: Data
    var encryptedNote: Data?
    var date: Date
    var category: Category?

    // Computed properties
    var amount: Decimal {
        get {
            do {
                let decryptedString = try SecurityUtils.decryptTransactionData(encryptedAmount)
                return Decimal(string: decryptedString) ?? 0
            } catch {
                print("Error decrypting amount: \(error)")
                return 0
            }
        }
        set {
            do {
                let stringValue = "\(newValue)"
                encryptedAmount = try SecurityUtils.encryptTransactionData(stringValue)
            } catch {
                print("Error encrypting amount: \(error)")
                // Обработка ошибки
            }
        }
    }
    
    var note: String? {
        get {
            guard let encryptedNote = encryptedNote else { return nil }
            do {
                return try SecurityUtils.decryptTransactionData(encryptedNote)
            } catch {
                print("Error decrypting note: \(error)")
                return nil
            }
        }
        set {
            do {
                if let newValue = newValue {
                    encryptedNote = try SecurityUtils.encryptTransactionData(newValue)
                } else {
                    encryptedNote = nil
                }
            } catch {
                print("Error encrypting note: \(error)")
                // Обработка ошибки
            }
        }
    }

    init(id: UUID = UUID(), amount: Decimal, note: String? = nil, date: Date = .now, category: Category? = nil) {
        self.id = id
        self.date = date
        self.category = category
        
        // Шифруем при инициализации
        do {
            let amountString = "\(amount)"
            self.encryptedAmount = try SecurityUtils.encryptTransactionData(amountString)
            if let note = note {
                self.encryptedNote = try SecurityUtils.encryptTransactionData(note)
            } else {
                self.encryptedNote = nil
            }
        } catch {
            print("Error encrypting transaction data during init: \(error)")
            self.encryptedAmount = Data()
            self.encryptedNote = nil
        }
    }
}

extension Category {
    static let sample: Category = {
        let c = Category(name: "Food")
        c.transactions = [
            Transaction(amount: 12.5, note: "Coffee", category: c),
            Transaction(amount: 25, note: "Lunch", category: c)
        ]
        return c
    }()
}

extension Transaction {
    static let sample = Transaction(amount: 9.99, note: "Snack")
}
