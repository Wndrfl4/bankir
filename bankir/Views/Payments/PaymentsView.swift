import SwiftUI

struct PaymentsView: View {

    struct PaymentService: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let color: Color
    }

    private var services: [PaymentService] = [
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

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    @State private var selectedService: PaymentService?
    @State private var isActive = false

    var body: some View {

        NavigationStack {

            ScrollView {

                LazyVGrid(columns: columns, spacing: 16) {

                    ForEach(services) { service in
                        NavigationLink(
                            destination: destinationView(for: service),
                            isActive: Binding(
                                get: { selectedService?.id == service.id && isActive },
                                set: { newValue in
                                    if newValue {
                                        selectedService = service
                                    } else {
                                        selectedService = nil
                                    }
                                    isActive = newValue
                                }
                            )
                        ) {
                            serviceButton(service)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                }
                .padding()

            }
            .navigationTitle("Платежи")
        }
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
        .frame(height: 90)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
        )
    }
}

#Preview {
    PaymentsView()
}
