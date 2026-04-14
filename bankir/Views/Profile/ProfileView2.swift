import SwiftUI

struct ProfileView: View {
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var notificationsEnabled: Bool = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundStyle(.tint)
                        .padding(.top, 24)

                    VStack(spacing: 12) {
                        profileCard
                        actionsCard
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Profile")
            .onAppear { loadOrCreateProfileIfNeeded() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveProfile() }
                }
            }
        }
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account")
                .font(.headline)

            TextField("Username", text: $username)
                .textContentType(.username)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Toggle("Notifications", isOn: $notificationsEnabled)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)

            Button(role: .destructive) {
                AuthManager.shared.logout()
                // Перезапуск или переход к логину
                // Для простоты, можно добавить @Environment(\.dismiss) или глобальное состояние
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func loadOrCreateProfileIfNeeded() {
        // Frontend-only: set default demo values
        if username.isEmpty && email.isEmpty {
            username = "Aslan"
            email = "user@example.com"
            notificationsEnabled = true
        }
    }

    private func saveProfile() {
        // Валидация
        guard ValidationUtils.isValidUsername(username) else {
            // Показать ошибку
            return
        }
        guard ValidationUtils.isValidEmail(email) else {
            // Показать ошибку
            return
        }
        // Сохранить (в реальности, отправить на сервер)
    }
}

#Preview {
    NavigationStack { ProfileView() }
}
