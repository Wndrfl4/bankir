import SwiftUI

struct HomeView: View {
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₸"
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_KZ")
        return formatter
    }()
    
    enum QuickAction: Hashable {
        case topUp
        case transfer
        case payBill
        case history
    }
    
    struct Transaction: Identifiable {
        enum Category: String {
            case shopping = "Покупки"
            case transfer = "Перевод"
            case mobile = "Связь"
            case utilities = "Коммунальные"
            case cashout = "Пополнение"
        }
        
        enum Status: String {
            case done = "Выполнено"
            case pending = "В ожидании"
            case failed = "Ошибка"
        }
        
        let id: String
        let title: String
        let category: Category
        let date: Date
        let amount: Decimal
        let isDebit: Bool
        let status: Status
    }
    
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showAllTransactions = false
    @State private var selectedTransaction: Transaction?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var balance: Decimal = 1_245_300
    @State private var iban: String = "KZ12 1234 5678 9876"
    @State private var transactions: [Transaction] = HomeView.guestTransactions
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
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
        .task(id: authManager.currentUserID) {
            await loadDashboard()
        }
        .sheet(isPresented: $showAllTransactions) {
            AllCompletedOperationsView(transactions: transactions)
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailsView(
                transaction: transaction,
                formattedAmount: formattedAmount(transaction.amount, isDebit: transaction.isDebit),
                formattedDate: Self.dateFormatter.string(from: transaction.date)
            )
            .presentationDetents([.medium])
        }
    }
    
    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Текущий баланс")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if isLoading && authManager.currentRole.isAuthenticated {
                ProgressView()
                    .tint(Theme.accentStrong)
                    .padding(.vertical, 8)
            } else {
                Text(formattedCurrency(balance))
                    .font(.system(size: 34, weight: .bold))
            }
            
            Text("Счет: \(formattedIBAN(iban))")
                .font(.footnote)
                .foregroundStyle(.secondary)
            
            if let loadError, authManager.currentRole.isAuthenticated {
                Text(loadError)
                    .font(.footnote)
                    .foregroundStyle(Theme.danger)
            }
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
                .disabled(transactions.isEmpty)
            }
            
            if transactions.isEmpty {
                Text(authManager.currentRole.isAuthenticated ? "Операций пока нет" : "Войдите, чтобы увидеть историю операций")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.regularMaterial)
                    )
            } else {
                VStack(spacing: 8) {
                    ForEach(transactions.prefix(5)) { tx in
                        transactionRow(tx)
                        if tx.id != transactions.prefix(5).last?.id {
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
    }
    
    private func transactionRow(_ tx: Transaction) -> some View {
        HStack(spacing: 12) {
            categoryIcon(tx.category)
                .frame(width: 40, height: 40)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(tx.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
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
                    Text(Self.dateFormatter.string(from: tx.date))
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
        case .shopping:
            name = "bag.fill"
            color = .blue
        case .transfer:
            name = "arrow.left.arrow.right"
            color = .orange
        case .mobile:
            name = "antenna.radiowaves.left.and.right"
            color = .purple
        case .utilities:
            name = "bolt.fill"
            color = .teal
        case .cashout:
            name = "banknote.fill"
            color = .green
        }
        
        return Image(systemName: name)
            .foregroundStyle(color)
            .font(.system(size: 18, weight: .semibold))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func statusChip(_ status: Transaction.Status) -> some View {
        let tint: Color
        let foreground: Color
        
        switch status {
        case .done:
            tint = .green.opacity(0.15)
            foreground = .green
        case .pending:
            tint = .orange.opacity(0.15)
            foreground = .orange
        case .failed:
            tint = .red.opacity(0.15)
            foreground = .red
        }
        
        return Text(status.rawValue)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint, in: Capsule())
            .foregroundStyle(foreground)
    }
    
    private func formattedAmount(_ amount: Decimal, isDebit: Bool) -> String {
        let sign = isDebit ? "-" : "+"
        return sign + formattedCurrency(amount)
    }
    
    private func formattedCurrency(_ amount: Decimal) -> String {
        let formatted = Self.currencyFormatter.string(from: amount as NSDecimalNumber) ?? "₸0"
        return formatted
    }
    
    private func formattedIBAN(_ value: String) -> String {
        value.replacingOccurrences(of: "\"", with: "")
    }
    
    @MainActor
    private func loadDashboard() async {
        guard authManager.currentRole.isAuthenticated else {
            loadError = nil
            balance = 1_245_300
            iban = "KZ12 1234 5678 9876"
            transactions = Self.guestTransactions
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let user = NetworkManager.shared.fetchCurrentUser()
            async let fetchedTransactions = NetworkManager.shared.fetchTransactions()
            
            let (profile, history) = try await (user, fetchedTransactions)
            if let primaryAccount = profile.accounts.first(where: { $0.isPrimary }) ?? profile.accounts.first {
                balance = primaryAccount.balance
                iban = primaryAccount.iban
            } else {
                balance = 0
                iban = "Счет не найден"
            }
            
            transactions = history.map { apiTransaction in
                mapTransaction(apiTransaction, currentUserId: profile.id)
            }
            loadError = nil
        } catch {
            loadError = error.localizedDescription
            transactions = []
        }
    }
    
    private func mapTransaction(_ transaction: APITransaction, currentUserId: String) -> Transaction {
        let category: Transaction.Category
        let title: String
        
        switch transaction.type {
        case "TRANSFER":
            category = .transfer
            title = transaction.note ?? "Перевод"
        case "TOP_UP":
            category = .cashout
            title = transaction.provider ?? "Пополнение"
        case "BILL_PAYMENT":
            category = .utilities
            title = transaction.billCategory ?? "Оплата услуг"
        default:
            category = .shopping
            title = transaction.note ?? "Операция"
        }
        
        let status: Transaction.Status
        switch transaction.status {
        case "SUCCESS":
            status = .done
        case "FAILED":
            status = .failed
        default:
            status = .pending
        }
        
        let isDebit = transaction.sourceUserId == currentUserId || transaction.type == "BILL_PAYMENT"
        
        return Transaction(
            id: transaction.id,
            title: title,
            category: category,
            date: transaction.createdAt,
            amount: transaction.amount,
            isDebit: isDebit,
            status: status
        )
    }
    
    private static let guestTransactions: [Transaction] = [
        .init(id: UUID().uuidString, title: "Магазин A", category: .shopping, date: Date().addingTimeInterval(-3600 * 5), amount: 15990, isDebit: true, status: .done),
        .init(id: UUID().uuidString, title: "Перевод Ивану", category: .transfer, date: Date().addingTimeInterval(-3600 * 26), amount: 25000, isDebit: true, status: .done),
        .init(id: UUID().uuidString, title: "Мобильная связь", category: .mobile, date: Date().addingTimeInterval(-3600 * 48), amount: 2990, isDebit: true, status: .done),
        .init(id: UUID().uuidString, title: "Пополнение счета", category: .cashout, date: Date().addingTimeInterval(-3600 * 60), amount: 50000, isDebit: false, status: .pending),
        .init(id: UUID().uuidString, title: "Коммунальные услуги", category: .utilities, date: Date().addingTimeInterval(-3600 * 90), amount: 12450, isDebit: true, status: .done),
    ]
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(transactions) { tx in
                        transactionRow(tx)
                        if tx.id != transactions.last?.id {
                            Divider()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Все операции")
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
                    Text(tx.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
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
                    Text(HomeView.dateFormatter.string(from: tx.date))
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
        case .shopping:
            name = "bag.fill"
            color = .blue
        case .transfer:
            name = "arrow.left.arrow.right"
            color = .orange
        case .mobile:
            name = "antenna.radiowaves.left.and.right"
            color = .purple
        case .utilities:
            name = "bolt.fill"
            color = .teal
        case .cashout:
            name = "banknote.fill"
            color = .green
        }
        
        return Image(systemName: name)
            .foregroundStyle(color)
            .font(.system(size: 18, weight: .semibold))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func statusChip(_ status: HomeView.Transaction.Status) -> some View {
        let tint: Color
        let foreground: Color
        
        switch status {
        case .done:
            tint = .green.opacity(0.15)
            foreground = .green
        case .pending:
            tint = .orange.opacity(0.15)
            foreground = .orange
        case .failed:
            tint = .red.opacity(0.15)
            foreground = .red
        }
        
        return Text(status.rawValue)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint, in: Capsule())
            .foregroundStyle(foreground)
    }
    
    private func formattedAmount(_ amount: Decimal, isDebit: Bool) -> String {
        let sign = isDebit ? "-" : "+"
        let formatted = HomeView.currencyFormatter.string(from: amount as NSDecimalNumber) ?? "₸0"
        return sign + formatted
    }
}

#Preview {
    HomeView()
}
