import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @EnvironmentObject private var preferences: AppPreferencesManager
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var show2FA = false
    
    private var isValidInput: Bool {
        ValidationUtils.isValidUsername(username) && !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()
                
                if show2FA {
                    TwoFactorView()
                } else {
                    loginForm
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
    }
    
    private var loginForm: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                        Text(preferences.text("Вход в Bankir", "Sign In to Bankir"))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        
                        Text(preferences.text("Выбери режим доступа: гость, пользователь или админ.", "Choose access mode: guest, user, or admin."))
                            .font(.body)
                            .foregroundStyle(Theme.mutedText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 16) {
                    authField(label: preferences.text("Имя пользователя", "Username")) {
                        TextField(
                            "",
                            text: $username,
                            prompt: Text("admin").foregroundStyle(Color.black.opacity(0.65))
                        )
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(Color.black)
                            .tint(Color.black)
                    }
                    
                    authField(label: preferences.text("Пароль", "Password")) {
                        SecureField(
                            "",
                            text: $password,
                            prompt: Text(preferences.text("Введите пароль", "Enter password"))
                                .foregroundStyle(Color.black.opacity(0.65))
                        )
                            .textContentType(.password)
                            .foregroundStyle(Color.black)
                            .tint(Color.black)
                    }
                    
                    if let error = errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Theme.danger)
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(Theme.danger)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.danger.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    
                    Button(action: login) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Theme.heroGradient)
                            
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                            } else {
                                Text(preferences.text("Войти", "Sign In"))
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                            }
                        }
                    }
                    .disabled(isLoading || !isValidInput)
                    
                    if canUseBiometrics() {
                        Button(action: authenticateWithBiometrics) {
                            Label(preferences.text("Войти по биометрии", "Use Biometrics"), systemImage: "faceid")
                                .font(.headline)
                                .foregroundStyle(Theme.accentStrong)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .disabled(isLoading)
                    }
                    
                    Button(preferences.text("Продолжить как гость", "Continue as Guest")) {
                        authManager.continueAsGuest()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.mutedText)
                    .disabled(isLoading)
                }
                .padding(20)
                .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(preferences.text("Вход через backend", "Backend Sign-In"))
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text(preferences.text("Локальные demo-аккаунты больше не используются.", "Local demo accounts are no longer used."))
                        .font(.footnote)
                        .foregroundStyle(Theme.mutedText)
                    Text(preferences.text("Сначала зарегистрируй пользователя через экран регистрации.", "Register a user first from the registration screen."))
                        .font(.footnote)
                        .foregroundStyle(Theme.mutedText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
        }
    }
    
    private func authField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.mutedText)
            
            content()
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    private func login() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let success = try await AuthManager.shared.login(username: username, password: password)
                if success {
                    show2FA = true
                } else {
                    errorMessage = preferences.text("Неверные учетные данные", "Invalid credentials")
                }
            } catch {
                errorMessage = preferences.text("Ошибка сети", "Network error") + ": \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    private func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    private func authenticateWithBiometrics() {
        let context = LAContext()
        let reason = preferences.text("Войдите с помощью биометрии", "Sign in with biometrics")
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    authManager.authenticateWithBiometrics()
                } else {
                    errorMessage = error?.localizedDescription ?? preferences.text("Биометрия не удалась", "Biometric authentication failed")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
    .environmentObject(AppPreferencesManager.shared)
}
