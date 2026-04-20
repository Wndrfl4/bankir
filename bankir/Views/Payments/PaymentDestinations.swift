import SwiftUI

public struct TravelView: View {
    public init() {}
    public var body: some View {
        content(title: "Путешествия", systemImage: "suitcase.fill", color: .orange)
            .navigationTitle("Путешествия")
    }
}

public struct DocumentsView: View {
    public init() {}
    public var body: some View {
        content(title: "Документы", systemImage: "doc.text.fill", color: .blue)
            .navigationTitle("Документы")
    }
}

public struct CinemaAfishaView: View {
    public init() {}
    public var body: some View {
        content(title: "Кино Афиша", systemImage: "film.fill", color: .purple)
            .navigationTitle("Кино Афиша")
    }
}

public struct OnlineStoreView: View {
    public init() {}
    public var body: some View {
        content(title: "Онлайн магазин", systemImage: "cart.fill", color: .green)
            .navigationTitle("Онлайн магазин")
    }
}

public struct TrainTicketsView: View {
    public init() {}
    public var body: some View {
        content(title: "ЖД билеты", systemImage: "train.side.front.car", color: .teal)
            .navigationTitle("ЖД билеты")
    }
}

public struct AirlineTicketsView: View {
    public init() {}
    public var body: some View {
        content(title: "Авиабилеты", systemImage: "airplane", color: .indigo)
            .navigationTitle("Авиабилеты")
    }
}

public struct UtilitiesView: View {
    public init() {}
    public var body: some View {
        content(title: "Коммунальные", systemImage: "bolt.fill", color: .yellow)
            .navigationTitle("Коммунальные")
    }
}

public struct GroceriesView: View {
    public init() {}
    public var body: some View {
        content(title: "Продукты", systemImage: "basket.fill", color: .pink)
            .navigationTitle("Продукты")
    }
}

public struct GamesView: View {
    public init() {}
    public var body: some View {
        content(title: "Игры", systemImage: "gamecontroller.fill", color: .red)
            .navigationTitle("Игры")
    }
}

// MARK: - Shared content builder
private func content(title: String, systemImage: String, color: Color) -> some View {
    ZStack {
        Theme.appBackground.ignoresSafeArea()
        
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    Image(systemName: systemImage)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(color.gradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    
                    Text(title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    
                    Text("Экран уже подключён в навигацию, но бизнес-логика и форма ещё не собраны.")
                        .font(.body)
                        .foregroundStyle(Theme.mutedText)
                }
                .padding(20)
                .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Что здесь будет")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    placeholderRow("Форма ввода и валидация")
                    placeholderRow("Выбор провайдера или сценария оплаты")
                    placeholderRow("Подтверждение операции и статус")
                }
                .padding(20)
                .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Статус")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Label("Экран в очереди на реализацию", systemImage: "clock.badge.exclamationmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.warning)
                }
                .padding(20)
                .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .padding()
        }
    }
}

private func placeholderRow(_ text: String) -> some View {
    HStack(spacing: 10) {
        Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(Theme.accent)
        Text(text)
            .foregroundStyle(Theme.ink)
        Spacer()
    }
}

#Preview("TravelView") { NavigationStack { TravelView() } }
#Preview("DocumentsView") { NavigationStack { DocumentsView() } }
#Preview("CinemaAfishaView") { NavigationStack { CinemaAfishaView() } }
#Preview("OnlineStoreView") { NavigationStack { OnlineStoreView() } }
#Preview("TrainTicketsView") { NavigationStack { TrainTicketsView() } }
#Preview("AirlineTicketsView") { NavigationStack { AirlineTicketsView() } }
#Preview("UtilitiesView") { NavigationStack { UtilitiesView() } }
#Preview("GroceriesView") { NavigationStack { GroceriesView() } }
#Preview("GamesView") { NavigationStack { GamesView() } }
