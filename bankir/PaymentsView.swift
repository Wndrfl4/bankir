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

struct TravelView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.orange.opacity(0.7), Color.red.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 30) {
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white, .orange)
                    .shadow(radius: 10)
                Text("Путешествуйте легко!")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                HStack(spacing: 20) {
                    travelCard(icon: "airplane.departure", title: "Бронирование", subtitle: "Авиабилеты и отели")
                    travelCard(icon: "tag.fill", title: "Акции", subtitle: "Лучшие предложения")
                    travelCard(icon: "globe", title: "Гиды", subtitle: "Ваш путеводитель")
                }
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Путешествия")
    }

    private func travelCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(.orange)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(width: 110, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
        )
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
    }
}

struct DocumentsView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 30) {
                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.white, .blue)
                    .shadow(radius: 10)
                Text("Все ваши документы — всегда под рукой")
                    .font(.title3).bold()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                VStack(alignment: .leading, spacing: 16) {
                    documentInfoCard(title: "Цифровое хранение", description: "Сохраняйте и управляйте всеми вашими документами в одном месте.")
                    documentInfoCard(title: "Безопасность", description: "Ваши данные надежно защищены и приватны.")
                    documentInfoCard(title: "Быстрый доступ", description: "Оперативно находите нужный документ в любой момент.")
                }
                .padding()
                .background(.thinMaterial)
                .cornerRadius(20)
                .padding(.horizontal)
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Документы")
    }

    private func documentInfoCard(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundColor(.blue)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.3))
        )
        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 3)
    }
}

struct CinemaAfishaView: View {
    private let trendingMovies: [String] = [
        "film", "film.fill", "play.rectangle.fill", "star.fill", "popcorn.fill"
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.purple.opacity(0.8), Color.indigo.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 25) {
                Image(systemName: "film.stack.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.white, .purple)
                    .shadow(radius: 10)
                Text("Смотрите лучшие фильмы и новинки!")
                    .font(.title3).bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(trendingMovies.indices, id: \.self) { index in
                            movieCard(systemImageName: trendingMovies[index])
                        }
                    }
                    .padding(.horizontal)
                }
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Кино афиша")
    }

    private func movieCard(systemImageName: String) -> some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .frame(width: 140, height: 200)
                .overlay(
                    Image(systemName: systemImageName)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.purple)
                        .padding(30)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 6)
            Text("Новинка")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

struct OnlineStoreView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.green.opacity(0.8), Color.green.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 30) {
                Image(systemName: "cart.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white, .green)
                    .shadow(radius: 10)
                Text("Лучшие предложения в онлайн магазине!")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                HStack(spacing: 20) {
                    storeCard(icon: "tag.fill", title: "Акции", subtitle: "Скидки и распродажи")
                    storeCard(icon: "gift.fill", title: "Новинки", subtitle: "Товары дня")
                }
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Онлайн магазин")
    }

    private func storeCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(.green)
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.85))
        }
        .frame(width: 120, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
        )
        .shadow(color: Color.black.opacity(0.22), radius: 5, x: 0, y: 5)
    }
}

struct TrainTicketsView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.teal.opacity(0.8), Color.blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 30) {
                Image(systemName: "train.side.front.car.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white, .teal)
                    .shadow(radius: 10)
                Text("Билеты на поезда — просто и быстро")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                HStack(spacing: 20) {
                    trainCard(icon: "tram.fill", title: "Расписание", subtitle: "Все направления")
                    trainCard(icon: "ticket.fill", title: "Бронирование", subtitle: "Без очередей")
                }
                Spacer()
            }
            .padding()
        }
        .navigationTitle("ЖД билеты")
    }

    private func trainCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(.teal)
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.85))
        }
        .frame(width: 120, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
        )
        .shadow(color: Color.black.opacity(0.22), radius: 5, x: 0, y: 5)
    }
}

struct AirlineTicketsView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.indigo.opacity(0.75), Color.blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 30) {
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white, .indigo)
                    .shadow(radius: 10)
                Text("Дешевые авиарейсы на любой вкус")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                HStack(spacing: 20) {
                    airplaneCard(icon: "airplane.departure", title: "Поиск рейсов", subtitle: "Удобный выбор")
                    airplaneCard(icon: "creditcard.fill", title: "Оплата онлайн", subtitle: "Безопасно и быстро")
                }
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Авиабилеты")
    }

    private func airplaneCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(.indigo)
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.85))
        }
        .frame(width: 120, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
        )
        .shadow(color: Color.black.opacity(0.22), radius: 5, x: 0, y: 5)
    }
}

// MARK: - New Views

struct UtilitiesView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.yellow.opacity(0.75), Color.blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 30) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white, .yellow)
                    .shadow(radius: 10)
                Text("Оплата коммунальных услуг")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                HStack(spacing: 20) {
                    utilityCard(icon: "lightbulb.fill", title: "Оплатить свет", subtitle: "Быстро и удобно")
                    utilityCard(icon: "drop.fill", title: "Оплатить воду", subtitle: "Прозрачно и надежно")
                }
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Коммунальные")
    }

    private func utilityCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(.yellow)
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.85))
        }
        .frame(width: 130, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.2))
        )
        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 6)
    }
}

struct GroceriesView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.pink.opacity(0.7), Color.green.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 30) {
                Image(systemName: "basket.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white, .pink)
                    .shadow(radius: 10)
                Text("Покупки продуктов")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                HStack(spacing: 20) {
                    groceryCard(icon: "tag.fill", title: "Скидки на продукты", subtitle: "Экономьте каждый день")
                    groceryCard(icon: "cart", title: "Лучшие супермаркеты", subtitle: "Выбор и качество")
                }
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Продукты")
    }

    private func groceryCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(.pink)
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .frame(width: 130, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.2))
        )
        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 6)
    }
}

struct GamesView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.red.opacity(0.7), Color.blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 30) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white, .red)
                    .shadow(radius: 10)
                Text("Игры и развлечения")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                HStack(spacing: 20) {
                    gameCard(icon: "star.fill", title: "Популярные игры", subtitle: "Лучшие хиты")
                    gameCard(icon: "tag.fill", title: "Скидки на игры", subtitle: "Экономьте сейчас")
                }
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Игры")
    }

    private func gameCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(.red)
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .frame(width: 130, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.2))
        )
        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 6)
    }
}

#Preview {
    PaymentsView()
}
#Preview {
    TravelView()
}

#Preview {
    DocumentsView()
}

#Preview {
    CinemaAfishaView()
}

#Preview {
    OnlineStoreView()
}
#Preview {
    TrainTicketsView()
}

#Preview {
    AirlineTicketsView()
}

#Preview {
    UtilitiesView()
}
#Preview {
    GroceriesView()
}

#Preview {
    GamesView()
}

