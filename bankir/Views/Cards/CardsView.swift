import SwiftUI

struct CardsView: View {

    struct Card: Identifiable {
        let id = UUID()
        let bank: String
        let number: String
        let holder: String
        let balance: String
        let color: Color
    }

    private var cards: [Card] = [
        .init(bank: "Kaspi Bank", number: "**** 4582", holder: "A. User", balance: "₸ 245 000", color: .red),
        .init(bank: "Halyk Bank", number: "**** 9012", holder: "A. User", balance: "₸ 520 400", color: .green),
        .init(bank: "Freedom Bank", number: "**** 7731", holder: "A. User", balance: "₸ 84 300", color: .blue)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {

                VStack(spacing: 16) {

                    // список карт
                    ForEach(cards) { card in
                        cardView(card)
                    }

                    // кнопка добавить карту
                    addCardButton

                }
                .padding()

            }
            .navigationTitle("Карты")
        }
    }

    private func cardView(_ card: Card) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text(card.bank)
                    .font(.headline)

                Spacer()

                Image(systemName: "creditcard.fill")
                    .font(.title3)
            }

            Text(card.number)
                .font(.title3)
                .fontWeight(.semibold)

            HStack {
                Text(card.holder)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(card.balance)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    private var addCardButton: some View {

        HStack {
            Image(systemName: "plus.circle.fill")
                .font(.title2)

            Text("Добавить карту")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
        )
    }

}

#Preview {
    CardsView()
}
