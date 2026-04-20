import SwiftUI

struct OnboardingView: View {
    @State private var isShowingLogin = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()
                
                VStack(spacing: 28) {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 20) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Theme.heroGradient)
                                .frame(width: 92, height: 92)
                            
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bankir")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                            
                            Text("Банк в телефоне без лишнего шума: платежи, карты, история и контроль доступа в одном месте.")
                                .font(.body)
                                .foregroundStyle(Theme.mutedText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 14) {
                        featureRow(icon: "bolt.fill", title: "Быстрые переводы", subtitle: "Платежи и пополнения без лишних шагов")
                        featureRow(icon: "shield.fill", title: "Безопасный вход", subtitle: "PIN, биометрия и контроль сессии")
                        featureRow(icon: "chart.line.uptrend.xyaxis", title: "Понятная история", subtitle: "Операции и категории в одном потоке")
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: LoginView(), isActive: $isShowingLogin) {
                        EmptyView()
                    }
                    .hidden()
                    
                    Button {
                        isShowingLogin = true
                    } label: {
                        Text("Продолжить")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .foregroundStyle(.white)
                            .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    
                    Text("Демо-вход: `admin/password` или `test/password`")
                        .font(.footnote)
                        .foregroundStyle(Theme.mutedText)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.accentStrong)
                .frame(width: 42, height: 42)
                .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Theme.mutedText)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
