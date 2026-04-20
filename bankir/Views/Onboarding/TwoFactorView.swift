import SwiftUI

struct TwoFactorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pin: String = ""
    @State private var errorMessage: String?
    @State private var isSettingPin = false
    @State private var newPin: String = ""
    @State private var confirmPin: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Подтверждение входа")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    
                    Text(isSettingPin ? "Создай PIN-код для следующего входа." : "Введи PIN-код, чтобы завершить авторизацию.")
                        .font(.body)
                        .foregroundStyle(Theme.mutedText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 16) {
                    if isSettingPin {
                        pinField(title: "Новый PIN", text: $newPin)
                        pinField(title: "Подтвердите PIN", text: $confirmPin)
                        
                        Button("Установить PIN") {
                            if newPin == confirmPin && newPin.count >= 4 {
                                AuthManager.shared.setPin(newPin)
                                errorMessage = nil
                                isSettingPin = false
                            } else {
                                errorMessage = "PIN должен быть не менее 4 символов и совпадать"
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(.white)
                        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .disabled(newPin.isEmpty || confirmPin.isEmpty)
                    } else {
                        pinField(title: "PIN", text: $pin)
                        
                        Button("Подтвердить") {
                            if AuthManager.shared.verify2FA(pin: pin) {
                                dismiss()
                            } else {
                                errorMessage = "Неверный PIN"
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(.white)
                        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .disabled(pin.isEmpty)
                        
                        Button("Установить новый PIN") {
                            isSettingPin = true
                            errorMessage = nil
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accentStrong)
                    }
                    
                    if let error = errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.slash.fill")
                                .foregroundStyle(Theme.danger)
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(Theme.danger)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.danger.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(20)
                .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                
                Spacer(minLength: 20)
            }
            .padding(24)
        }
    }
    
    private func pinField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.mutedText)
            
            SecureField(title, text: text)
                .keyboardType(.numberPad)
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
