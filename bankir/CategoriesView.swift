import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor<Category>(\.createdAt, order: .reverse)]) private var categories: [Category]

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    NavigationLink(destination: TransactionsView(category: category)) {
                        HStack {
                            Text(category.name)
                            Spacer()
                            Text(category.totalAmount, format: .currency(code: Locale.current.currencyCode ?? "USD"))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteCategories)
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        addCategory()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func addCategory() {
        let newCategory = Category(name: "Category \(Date().formatted(.dateTime.hour().minute().second()))", createdAt: Date())
        context.insert(newCategory)
        try? context.save()
    }

    private func deleteCategories(offsets: IndexSet) {
        for index in offsets {
            context.delete(categories[index])
        }
        try? context.save()
    }
}

struct TransactionsView: View {
    let category: Category
    @Environment(\.modelContext) private var context
    @Query private var transactions: [Transaction]

    init(category: Category) {
        self.category = category
        let categoryName = category.name
        _transactions = Query(
            filter: #Predicate { t in
                t.category?.name == categoryName
            },
            sort: [SortDescriptor<Transaction>(\.date, order: .reverse)]
        )
    }

    var body: some View {
        List {
            ForEach(transactions) { transaction in
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.amount, format: .currency(code: Locale.current.currencyCode ?? "USD"))
                        .font(.headline)
                    if let note = transaction.note {
                        Text(note)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text(transaction.date, format: .dateTime.year().month().day())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onDelete(perform: deleteTransactions)
        }
        .navigationTitle(category.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    addRandomTransaction()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func addRandomTransaction() {
        let amount = Decimal(Double.random(in: 1...100))
        let newTransaction = Transaction(amount: amount, note: "Random Transaction", date: Date(), category: category)
        context.insert(newTransaction)
        try? context.save()
    }

    private func deleteTransactions(offsets: IndexSet) {
        for index in offsets {
            context.delete(transactions[index])
        }
        try? context.save()
    }
}

#Preview {
    CategoriesPreview()
}

private struct CategoriesPreview: View {
    let container: ModelContainer = {
        let container = try! ModelContainer(
            for: Category.self, Transaction.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let cat1 = Category(name: "Groceries", createdAt: Date().addingTimeInterval(-3600))
        let cat2 = Category(name: "Utilities", createdAt: Date())
        context.insert(cat1)
        context.insert(cat2)

        let t1 = Transaction(amount: Decimal(Double(50.25)), note: "Supermarket", date: Date().addingTimeInterval(-1800), category: cat1)
        let t2 = Transaction(amount: Decimal(Double(120.0)), note: "Electric Bill", date: Date(), category: cat2)
        context.insert(t1)
        context.insert(t2)

        try? context.save()
        return container
    }()

    var body: some View {
        CategoriesView()
            .modelContainer(container)
    }
}
