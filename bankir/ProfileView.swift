import SwiftUI
import SwiftData

// Wrapper view to avoid name conflicts with the main ProfileView
struct BankirProfileView: View {
    var body: some View {
        NavigationStack {
            ProfileView()
        }
        .navigationTitle("Профиль")
    }
}
#Preview {
    let container = try! ModelContainer(
        for: UserProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    BankirProfileView()
        .modelContainer(container)
}

struct TabBarRootView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Главная", systemImage: "house") }
            .tag(0)

            NavigationStack {
                CardsView()
            }
            .tabItem { Label("Карты", systemImage: "creditcard") }
            .tag(1)

            NavigationStack {
                PaymentsView()
            }
            .tabItem { Label("Платежи", systemImage: "list.bullet.rectangle") }
            .tag(2)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Профиль", systemImage: "person.crop.circle") }
            .tag(3)
        }
    }
}

#Preview {
    TabBarRootView()
}

