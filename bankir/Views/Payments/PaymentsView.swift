import SwiftUI

struct PaymentsView: View {
    private static let services: [PaymentService] = [
        .init(title: "Путешествия", icon: "suitcase.fill", color: .orange),
        .init(title: "Документы", icon: "doc.text.fill", color: .blue),
        .init(title: "Кино Афиша", icon: "film.fill", color: .purple),
        .init(title: "Онлайн магазин", icon: "cart.fill", color: .green),
        .init(title: "ЖД билеты", icon: "train.side.front.car", color: .teal),
        .init(title: "Авиабилеты", icon: "airplane", color: .indigo),
        .init(title: "Коммунальные", icon: "bolt.fill", color: .yellow),
        .init(title: "Продукты", icon: "basket.fill", color: .pink),
        .init(title: "Игры", icon: "gamecontroller.fill", color: .red)
    ]
    
    private static let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    enum QuickPaymentAction: String, Identifiable {
        case transfer = "Перевод"
        case topUp = "Пополнение"
        case payBill = "Оплата услуг"
        
        var id: String { rawValue }
    }

    struct PaymentService: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let color: Color
    }

    @State private var selectedQuickAction: QuickPaymentAction?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        hero
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Популярные действия")
                                .font(.headline)
                                .foregroundStyle(Theme.ink)
                            
                            HStack(spacing: 12) {
                                quickActionCard(title: "Перевод", subtitle: "На карту", icon: "arrow.left.arrow.right.circle.fill", color: .blue, action: .transfer)
                                quickActionCard(title: "Пополнение", subtitle: "Мобильный", icon: "iphone.gen3.radiowaves.left.and.right", color: .green, action: .topUp)
                                quickActionCard(title: "Услуги", subtitle: "Коммунальные", icon: "bolt.circle.fill", color: .orange, action: .payBill)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Каталог сервисов")
                                .font(.headline)
                                .foregroundStyle(Theme.ink)
                            
                            LazyVGrid(columns: Self.columns, spacing: 16) {
                                ForEach(Self.services) { service in
                                    NavigationLink(destination: destinationView(for: service)) {
                                        serviceButton(service)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Платежи")
            .sheet(item: $selectedQuickAction) { action in
                NavigationStack {
                    switch action {
                    case .transfer:
                        TransferScreen()
                    case .topUp:
                        TopUpScreen()
                    case .payBill:
                        PayBillScreen()
                    }
                }
            }
        }
    }
    
    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Платежи без очередей")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Быстрые действия сверху, остальные сервисы ниже как каталог.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private func destinationView(for service: PaymentService) -> some View {
        switch service.title {
        case "Путешествия":
            TravelView()
        case "Документы":
            DocumentsView()
        case "Кино Афиша":
            CinemaAfishaView()
        case "Онлайн магазин":
            OnlineStoreView()
        case "ЖД билеты":
            TrainTicketsView()
        case "Авиабилеты":
            AirlineTicketsView()
        case "Коммунальные":
            UtilitiesView()
        case "Продукты":
            GroceriesView()
        case "Игры":
            GamesView()
        default:
            EmptyView()
        }
    }

    private func serviceButton(_ service: PaymentService) -> some View {
        VStack(spacing: 10) {
            Image(systemName: service.icon)
                .font(.system(size: 26))
                .foregroundStyle(service.color)
            
            Text(service.title)
                .font(.footnote)
                .multilineTextAlignment(.center)
        }
        .frame(height: 96)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Theme.secondaryCardBackground)
        )
    }
    
    private func quickActionCard(title: String, subtitle: String, icon: String, color: Color, action: QuickPaymentAction) -> some View {
        Button {
            selectedQuickAction = action
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(color)
                
                Spacer()
                
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
            }
            .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
            .padding(16)
            .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaymentsView()
}
