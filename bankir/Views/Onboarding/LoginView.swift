import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showBiometric = false
    @State private var show2FA = false
    
    private var isValidInput: Bool {
        ValidationUtils.isValidUsername(username) && ValidationUtils.isValidPassword(password)
    }
    
    var body: some View {
        NavigationStack {
            if show2FA {
                TwoFactorView()
            } else {
                loginForm
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
    
    private var loginForm: some View {
        VStack(spacing: 16) {
            Text("Вход в Bankir")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Имя пользователя", text: $username)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            SecureField("Пароль", text: $password)
                .textFieldStyle(.roundedBorder)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: login) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Войти")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(isLoading || !isValidInput)
            
            if canUseBiometrics() {
                Button(action: authenticateWithBiometrics) {
                    Text("Войти с помощью биометрии")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isLoading)
            }
        }
        .padding()
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
                    // Предполагаем, что биометрия заменяет логин
                    // В реальности, связать с аккаунтом
                    AuthManager.shared.saveToken("biometricToken") // Mock
                    // Переход
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
