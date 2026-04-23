import SwiftUI

struct RegisterView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @EnvironmentObject private var preferences: AppPreferencesManager
    
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
                        Text(preferences.text("Регистрация", "Registration"))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        
                        Text(preferences.text("Создай аккаунт. Данные будут сохранены в backend и станут доступны после входа.", "Create an account. Your data will be stored in the backend and available after sign in."))
                            .font(.body)
                            .foregroundStyle(Theme.mutedText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        formField(title: preferences.text("Имя пользователя", "Username"), text: $username, placeholder: "aslan_user")
                        formField(title: "Email", text: $email, placeholder: "user@example.com", keyboard: .emailAddress)
                        secureField(title: preferences.text("Пароль", "Password"), text: $password, placeholder: preferences.text("Минимум 6 символов", "Minimum 6 characters"))
                        secureField(title: preferences.text("Подтвердите пароль", "Confirm Password"), text: $confirmPassword, placeholder: preferences.text("Повтори пароль", "Repeat password"))
                        
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
                                Text(preferences.text("Создать аккаунт", "Create Account"))
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
        .navigationTitle(preferences.text("Новый аккаунт", "New Account"))
    }
    
    private func register() {
        errorMessage = nil
        
        guard password == confirmPassword else {
            errorMessage = preferences.text("Пароли не совпадают", "Passwords do not match")
            return
        }
        
        isSaving = true
        Task {
            do {
                try await authManager.register(username: username, email: email, password: password)
            } catch {
                errorMessage = preferences.text("Не удалось создать аккаунт", "Failed to create account") + ": \(error.localizedDescription)"
            }
            
            isSaving = false
        }
    }
    
    private func formField(title: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.mutedText)
            TextField(
                "",
                text: text,
                prompt: Text(placeholder).foregroundStyle(Color.black.opacity(0.65))
            )
                .keyboardType(keyboard)
                .textContentType(keyboard == .emailAddress ? .emailAddress : .username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(Color.black)
                .tint(Color.black)
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    private func secureField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.mutedText)
            SecureField(
                "",
                text: text,
                prompt: Text(placeholder).foregroundStyle(Color.black.opacity(0.65))
            )
                .textContentType(.newPassword)
                .foregroundStyle(Color.black)
                .tint(Color.black)
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AppPreferencesManager.shared)
}
