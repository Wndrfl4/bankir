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

