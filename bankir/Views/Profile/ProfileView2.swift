import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var authManager = AuthManager.shared
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var notificationsEnabled: Bool = true

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        profileHeader
                        
                        VStack(spacing: 12) {
                            if authManager.hasAccess(to: .profileEditing) {
                                profileCard
                            } else {
                                guestCard
                            }
                            actionsCard
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Profile")
            .onAppear { loadOrCreateProfileIfNeeded() }
            .toolbar {
                if authManager.hasAccess(to: .profileEditing) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") { saveProfile() }
                    }
                }
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(.white)
                .padding(.top, 24)
            
            Text(authManager.currentRole.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.86))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.16), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 24)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal)
        .padding(.top, 12)
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account")
                .font(.headline)
                .foregroundStyle(Theme.ink)

            TextField("Username", text: $username)
                .textContentType(.username)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Toggle("Notifications", isOn: $notificationsEnabled)
                .tint(Theme.accent)
        }
        .padding()
        .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)
                .foregroundStyle(Theme.ink)

            if authManager.currentRole == .guest {
                NavigationLink {
                    LoginView()
                } label: {
                    Label("Sign In", systemImage: "person.badge.key.fill")
                        .foregroundStyle(Theme.accentStrong)
                }
            } else {
                Button(role: .destructive) {
                    authManager.logout()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private var guestCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Guest Access")
                .font(.headline)
                .foregroundStyle(Theme.ink)
            
            Text("Гость может просматривать главную страницу и профиль, но не может пользоваться платежами, картами и настройками аккаунта.")
                .font(.subheadline)
                .foregroundStyle(Theme.mutedText)
        }
        .padding()
        .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func loadOrCreateProfileIfNeeded() {
        guard authManager.hasAccess(to: .profileEditing) else {
            username = "Guest"
            email = ""
            notificationsEnabled = false
            return
        }
        
        if let profileID = authManager.currentProfileID {
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = (try? modelContext.fetch(descriptor)) ?? []
            if let profile = profiles.first(where: { $0.id == profileID }) {
                username = profile.username
                email = profile.email
                notificationsEnabled = profile.notificationsEnabled
                return
            }
        }
        
        username = authManager.currentRole == .admin ? "Admin" : "Aslan"
        email = authManager.currentRole == .admin ? "admin@example.com" : "user@example.com"
        notificationsEnabled = true
    }

    private func saveProfile() {
        guard authManager.hasAccess(to: .profileEditing) else { return }
        
        // Валидация
        guard ValidationUtils.isValidUsername(username) else {
            // Показать ошибку
            return
        }
        guard ValidationUtils.isValidEmail(email) else {
            // Показать ошибку
            return
        }
        
        guard let profileID = authManager.currentProfileID else { return }
        
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? modelContext.fetch(descriptor)) ?? []
        guard let profile = profiles.first(where: { $0.id == profileID }) else { return }
        
        profile.username = username
        profile.email = email
        profile.notificationsEnabled = notificationsEnabled
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack { ProfileView() }
}
