import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var createdAt: Date
    @Relationship(inverse: \Transaction.category)
    var transactions: [Transaction]

    init(id: UUID = UUID(), name: String, createdAt: Date = .now, transactions: [Transaction] = []) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.transactions = transactions
    }

    var totalAmount: Decimal {
        transactions.reduce(0) { $0 + $1.amount }
    }
}

@Model
final class Transaction {
    var id: UUID
    var amount: Decimal
    var note: String?
    var date: Date
    var category: Category?

    init(id: UUID = UUID(), amount: Decimal, note: String? = nil, date: Date = .now, category: Category? = nil) {
        self.id = id
        self.amount = amount
        self.note = note
        self.date = date
        self.category = category
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
