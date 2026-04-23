import SwiftUI

struct CardsView: View {
    struct Card: Identifiable {
        let id = UUID()
        let bank: String
        let number: String
        let holder: String
        let balance: String
        let gradient: LinearGradient
    }
    
    @State private var cards: [Card] = [
        .init(bank: "Kaspi Bank", number: "**** 4582", holder: "A. User", balance: "₸ 245 000", gradient: LinearGradient(colors: [Color(red: 0.78, green: 0.12, blue: 0.18), Color(red: 0.92, green: 0.34, blue: 0.28)], startPoint: .topLeading, endPoint: .bottomTrailing)),
        .init(bank: "Halyk Bank", number: "**** 9012", holder: "A. User", balance: "₸ 520 400", gradient: LinearGradient(colors: [Color(red: 0.02, green: 0.42, blue: 0.24), Color(red: 0.15, green: 0.62, blue: 0.42)], startPoint: .topLeading, endPoint: .bottomTrailing)),
        .init(bank: "Freedom Bank", number: "**** 7731", holder: "A. User", balance: "₸ 84 300", gradient: LinearGradient(colors: [Color(red: 0.08, green: 0.22, blue: 0.56), Color(red: 0.25, green: 0.48, blue: 0.86)], startPoint: .topLeading, endPoint: .bottomTrailing))
    ]
    @State private var isPresentingAddCard = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        summaryCard
                        
                        ForEach(cards) { card in
                            cardView(card)
                        }
                        
                        addCardButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Карты")
            .sheet(isPresented: $isPresentingAddCard) {
                AddCardSheet { card in
                    cards.insert(card, at: 0)
                }
            }
        }
    }
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Мои карты")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.86))
            Text("\(cards.count)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Привязанные карты и быстрый доступ к добавлению новой.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.82))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func cardView(_ card: Card) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(card.bank)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Image(systemName: "creditcard.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            Text(card.number)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            
            HStack {
                Text(card.holder)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.76))
                
                Spacer()
                
                Text(card.balance)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(card.gradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 90, height: 90)
                .offset(x: 24, y: -26)
        }
    }

    private var addCardButton: some View {
        Button {
            isPresentingAddCard = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.accentStrong)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Добавить карту")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.ink)
                    Text("Открыть форму привязки карты")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedText)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.secondaryCardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CardsView()
}

private struct AddCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var bank = ""
    @State private var lastFourDigits = ""
    @State private var holder = ""
    @State private var balance = ""
    
    let onSave: (CardsView.Card) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        sheetField(title: "Банк", text: $bank, placeholder: "Например, Jusan Bank")
                        sheetField(title: "Последние 4 цифры", text: $lastFourDigits, placeholder: "4582", keyboard: .numberPad)
                        sheetField(title: "Держатель", text: $holder, placeholder: "A. User")
                        sheetField(title: "Баланс", text: $balance, placeholder: "₸ 50 000")
                        
                        Button("Сохранить") {
                            let card = CardsView.Card(
                                bank: bank,
                                number: "**** \(lastFourDigits)",
                                holder: holder,
                                balance: balance,
                                gradient: LinearGradient(colors: [Theme.accentStrong, Theme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            onSave(card)
                            dismiss()
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(.white)
                        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .disabled(bank.isEmpty || lastFourDigits.count != 4 || holder.isEmpty || balance.isEmpty)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Новая карта")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
    
    private func sheetField(title: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.mutedText)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
