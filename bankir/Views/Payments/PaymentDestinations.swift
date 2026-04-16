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
    VStack(spacing: 16) {
        Image(systemName: systemImage)
            .font(.system(size: 48))
            .foregroundStyle(color)
        Text(title)
            .font(.title3)
            .bold()
        Text("Заглушка экрана. Замените на реальную реализацию.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
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
