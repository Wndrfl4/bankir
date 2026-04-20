import SwiftUI

struct HomeView: View {
    enum QuickAction: Hashable {
        case topUp
        case transfer
        case payBill
        case history
    }
    
    @State private var showAllTransactions = false
    @State private var selectedTransaction: Transaction?

    struct Transaction: Identifiable {
        enum Category: String {
            case shopping = "Покупки"
            case transfer = "Перевод"
            case mobile = "Связь"
            case utilities = "Коммунальные"
            case cashout = "Снятие"
        }
        enum Status: String { case done = "Выполнено"; case pending = "В ожидании" }
        let id = UUID()
        let title: String
        let category: Category
        let date: Date
        let amount: Decimal
        let isDebit: Bool
        let status: Status
    }

    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "₸"
        f.maximumFractionDigits = 0
        return f
    }

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        df.locale = Locale(identifier: "ru_KZ")
        return df
    }

    private var transactions: [Transaction] = [
        .init(title: "Магазин A", category: .shopping, date: Date().addingTimeInterval(-3600*5), amount: 15990, isDebit: true, status: .done),
        .init(title: "Перевод Ивану", category: .transfer, date: Date().addingTimeInterval(-3600*26), amount: 25000, isDebit: true, status: .done),
        .init(title: "Мобильная связь", category: .mobile, date: Date().addingTimeInterval(-3600*48), amount: 2990, isDebit: true, status: .done),
        .init(title: "Пополнение счета", category: .cashout, date: Date().addingTimeInterval(-3600*60), amount: 50000, isDebit: false, status: .pending),
        .init(title: "Коммунальные услуги", category: .utilities, date: Date().addingTimeInterval(-3600*90), amount: 12450, isDebit: true, status: .done)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        balanceCard
                        quickActions
                        recentSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Главная")
            .navigationDestination(for: QuickAction.self) { action in
                switch action {
                case .topUp:
                    TopUpScreen()
                case .transfer:
                    TransferScreen()
                case .payBill:
                    PayBillScreen()
                case .history:
                    AllCompletedOperationsView(transactions: transactions)
                }
            }
        }
        .sheet(isPresented: $showAllTransactions) {
            AllCompletedOperationsView(transactions: transactions.filter { $0.status == .done })
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailsView(transaction: transaction, formattedAmount: formattedAmount(transaction.amount, isDebit: transaction.isDebit), formattedDate: dateFormatter.string(from: transaction.date))
                .presentationDetents([.medium])
        }
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Текущий баланс")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("₸ 1 245 300")
                .font(.system(size: 34, weight: .bold))
            Text("Счет: KZ12 1234 5678 9876")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            actionButton(icon: "arrow.down.circle.fill", title: "Пополнить", action: .topUp)
            actionButton(icon: "arrow.up.circle.fill", title: "Перевод", action: .transfer)
            actionButton(icon: "creditcard.circle.fill", title: "Оплатить", action: .payBill)
            actionButton(icon: "clock.fill", title: "История", action: .history)
        }
        .frame(maxWidth: .infinity)
    }

    private func actionButton(icon: String, title: String, action: QuickAction) -> some View {
        NavigationLink(value: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .symbolRenderingMode(.hierarchical)
                Text(title)
                    .font(.footnote)
            }
            .frame(width: 80, height: 80)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Последние операции")
                    .font(.headline)
                Spacer()
                Button("Показать все") {
                    showAllTransactions = true
                }
                .font(.subheadline)
            }

            VStack(spacing: 8) {
                ForEach(transactions) { tx in
                    transactionRow(tx)
                    if tx.id != transactions.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.regularMaterial)
            )
        }
    }

    private func transactionRow(_ tx: Transaction) -> some View {
        HStack(spacing: 12) {
            categoryIcon(tx.category)
                .frame(width: 40, height: 40)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(tx.title).font(.subheadline).fontWeight(.semibold)
                    Spacer()
                    Text(formattedAmount(tx.amount, isDebit: tx.isDebit))
                        .font(.subheadline)
                        .foregroundStyle(tx.isDebit ? AnyShapeStyle(.primary) : AnyShapeStyle(Color.green))
                }
                HStack(spacing: 8) {
                    Text(tx.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(dateFormatter.string(from: tx.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    statusChip(tx.status)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTransaction = tx
        }
    }

    private func categoryIcon(_ category: Transaction.Category) -> some View {
        let name: String
        let color: Color
        switch category {
        case .shopping: name = "bag.fill"; color = .blue
        case .transfer: name = "arrow.left.arrow.right"; color = .orange
        case .mobile: name = "antenna.radiowaves.left.and.right"; color = .purple
        case .utilities: name = "bolt.fill"; color = .teal
        case .cashout: name = "banknote.fill"; color = .green
        }
        return Image(systemName: name)
            .foregroundStyle(color)
            .font(.system(size: 18, weight: .semibold))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func statusChip(_ status: Transaction.Status) -> some View {
        let text: String = status.rawValue
        let tint: Color = (status == .done) ? .green.opacity(0.15) : .orange.opacity(0.15)
        let fg: Color = (status == .done) ? .green : .orange
        return Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint, in: Capsule())
            .foregroundStyle(fg)
    }

    private func formattedAmount(_ amount: Decimal, isDebit: Bool) -> String {
        let sign = isDebit ? "-" : "+"
        let ns = amount as NSDecimalNumber
        let formatted = currencyFormatter.string(from: ns) ?? "₸0"
        return sign + formatted
    }
}

private struct TransactionDetailsView: View {
    let transaction: HomeView.Transaction
    let formattedAmount: String
    let formattedDate: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 42, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
            
            Text(transaction.title)
                .font(.title2.weight(.bold))
            
            Text(formattedAmount)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(transaction.isDebit ? Theme.ink : Theme.success)
            
            detailRow(title: "Категория", value: transaction.category.rawValue)
            detailRow(title: "Дата", value: formattedDate)
            detailRow(title: "Статус", value: transaction.status.rawValue)
            
            Spacer()
        }
        .padding(24)
        .background(Theme.appBackground)
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Theme.mutedText)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 6)
    }
}

private struct AllCompletedOperationsView: View {
    let transactions: [HomeView.Transaction]

    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "₸"
        f.maximumFractionDigits = 0
        return f
    }

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        df.locale = Locale(identifier: "ru_KZ")
        return df
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(transactions) { tx in
                        transactionRow(tx)
                        if tx.id != transactions.last?.id {
                            Divider()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Все выполненные операции")
        }
    }

    @ViewBuilder
    private func transactionRow(_ tx: HomeView.Transaction) -> some View {
        HStack(spacing: 12) {
            categoryIcon(tx.category)
                .frame(width: 40, height: 40)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(tx.title).font(.subheadline).fontWeight(.semibold)
                    Spacer()
                    Text(formattedAmount(tx.amount, isDebit: tx.isDebit))
                        .font(.subheadline)
                        .foregroundStyle(tx.isDebit ? AnyShapeStyle(.primary) : AnyShapeStyle(Color.green))
                }
                HStack(spacing: 8) {
                    Text(tx.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(dateFormatter.string(from: tx.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    statusChip(tx.status)
                }
            }
        }
        .contentShape(Rectangle())
    }

    private func categoryIcon(_ category: HomeView.Transaction.Category) -> some View {
        let name: String
        let color: Color
        switch category {
        case .shopping: name = "bag.fill"; color = .blue
        case .transfer: name = "arrow.left.arrow.right"; color = .orange
        case .mobile: name = "antenna.radiowaves.left.and.right"; color = .purple
        case .utilities: name = "bolt.fill"; color = .teal
        case .cashout: name = "banknote.fill"; color = .green
        }
        return Image(systemName: name)
            .foregroundStyle(color)
            .font(.system(size: 18, weight: .semibold))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func statusChip(_ status: HomeView.Transaction.Status) -> some View {
        let text: String = status.rawValue
        let tint: Color = (status == .done) ? .green.opacity(0.15) : .orange.opacity(0.15)
        let fg: Color = (status == .done) ? .green : .orange
        return Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint, in: Capsule())
            .foregroundStyle(fg)
    }

    private func formattedAmount(_ amount: Decimal, isDebit: Bool) -> String {
        let sign = isDebit ? "-" : "+"
        let ns = amount as NSDecimalNumber
        let formatted = currencyFormatter.string(from: ns) ?? "₸0"
        return sign + formatted
    }
}

#Preview {
    HomeView()
}
