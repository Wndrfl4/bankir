import SwiftUI
import SwiftData

struct RegisterView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var authManager = AuthManager.shared
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isSaving = false
    
    private var isValidForm: Bool {
        ValidationUtils.isValidUsername(username)
        && ValidationUtils.isValidEmail(email)
        && ValidationUtils.isValidPassword(password)
        && password == confirmPassword
    }
    
    var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Регистрация")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        
                        Text("Создай аккаунт. Имя, почта и пароль будут сохранены локально в приложении.")
                            .font(.body)
                            .foregroundStyle(Theme.mutedText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        formField(title: "Имя пользователя", text: $username, placeholder: "Например, aslan_user")
                        formField(title: "Email", text: $email, placeholder: "user@example.com", keyboard: .emailAddress)
                        secureField(title: "Пароль", text: $password, placeholder: "Минимум 6 символов")
                        secureField(title: "Подтвердите пароль", text: $confirmPassword, placeholder: "Повтори пароль")
                        
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(Theme.danger)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.danger.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        
                        Button {
                            register()
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                            } else {
                                Text("Создать аккаунт")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .disabled(isSaving || !isValidForm)
                    }
                    .padding(20)
                    .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .padding(24)
            }
        }
        .navigationTitle("Новый аккаунт")
    }
    
    private func register() {
        errorMessage = nil
        
        guard password == confirmPassword else {
            errorMessage = "Пароли не совпадают"
            return
        }
        
        isSaving = true
        
        let descriptor = FetchDescriptor<UserProfile>()
        let existingProfiles = (try? modelContext.fetch(descriptor)) ?? []
        
        if existingProfiles.contains(where: { $0.username.lowercased() == username.lowercased() }) {
            errorMessage = "Пользователь с таким именем уже существует"
            isSaving = false
            return
        }
        
        if existingProfiles.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            errorMessage = "Аккаунт с таким email уже существует"
            isSaving = false
            return
        }
        
        let profile = UserProfile(username: username, email: email, password: password, role: .user)
        modelContext.insert(profile)
        
        do {
            try modelContext.save()
            authManager.signIn(as: .user, profileID: profile.id)
        } catch {
            errorMessage = "Не удалось сохранить аккаунт"
        }
        
        isSaving = false
    }
    
    private func formField(title: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.mutedText)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textContentType(keyboard == .emailAddress ? .emailAddress : .username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    private func secureField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.mutedText)
            SecureField(placeholder, text: text)
                .textContentType(.newPassword)
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

#Preview {
    RegisterView()
}
