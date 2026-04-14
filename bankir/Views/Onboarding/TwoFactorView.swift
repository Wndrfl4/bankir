import SwiftUI

struct TwoFactorView: View {
    @State private var pin: String = ""
    @State private var errorMessage: String?
    @State private var isSettingPin = false
    @State private var newPin: String = ""
    @State private var confirmPin: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Двухфакторная аутентификация")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if isSettingPin {
                // Экран установки PIN
                Text("Установите PIN-код")
                    .font(.headline)
                
                SecureField("Новый PIN", text: $newPin)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                
                SecureField("Подтвердите PIN", text: $confirmPin)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                
                Button("Установить PIN") {
                    if newPin == confirmPin && newPin.count >= 4 {
                        AuthManager.shared.setPin(newPin)
                        isSettingPin = false
                    } else {
                        errorMessage = "PIN должен быть не менее 4 символов и совпадать"
                    }
                }
                .disabled(newPin.isEmpty || confirmPin.isEmpty)
            } else {
                // Экран ввода PIN
                Text("Введите PIN-код")
                    .font(.headline)
                
                SecureField("PIN", text: $pin)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button("Подтвердить") {
                    if AuthManager.shared.verify2FA(pin: pin) {
                        // Успех, переход к app
                        // Использовать @Environment(\.dismiss) или глобальное состояние
                    } else {
                        errorMessage = "Неверный PIN"
                    }
                }
                .disabled(pin.isEmpty)
                
                Button("Установить новый PIN") {
                    isSettingPin = true
                    errorMessage = nil
                }
            }
            
            Spacer()
        }
        .padding()
    }
}