import SwiftUI
import LocalAuthentication
import SwiftData

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var authManager = AuthManager.shared
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
                    Text("Вход в Bankir")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    
                    Text("Выбери режим доступа: гость, пользователь или админ.")
                        .font(.body)
                        .foregroundStyle(Theme.mutedText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 16) {
                    authField(label: "Имя пользователя") {
                        TextField("Например, admin", text: $username)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    
                    authField(label: "Пароль") {
                        SecureField("Введите пароль", text: $password)
                            .textContentType(.password)
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
                                Text("Войти")
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
                            Label("Войти по биометрии", systemImage: "faceid")
                                .font(.headline)
                                .foregroundStyle(Theme.accentStrong)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .disabled(isLoading)
                    }
                    
                    Button("Продолжить как гость") {
                        authManager.continueAsGuest()
                        dismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.mutedText)
                    .disabled(isLoading)
                }
                .padding(20)
                .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Демо-аккаунты")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text("admin / password -> админ")
                        .font(.footnote)
                        .foregroundStyle(Theme.mutedText)
                    Text("test / password -> пользователь")
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
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = (try? modelContext.fetch(descriptor)) ?? []
            
            if let profile = profiles.first(where: { $0.username.lowercased() == username.lowercased() && $0.password == password }) {
                authManager.signIn(as: profile.role, profileID: profile.id)
                dismiss()
                isLoading = false
                return
            }
            
            do {
                let success = try await AuthManager.shared.login(username: username, password: password)
                if success {
                    show2FA = true
                } else {
                    errorMessage = "Неверные учетные данные"
                }
            } catch {
                errorMessage = "Ошибка сети: \(error.localizedDescription)"
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
        let reason = "Войдите с помощью биометрии"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    authManager.authenticateWithBiometrics()
                    dismiss()
                } else {
                    errorMessage = error?.localizedDescription ?? "Биометрия не удалась"
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
}
