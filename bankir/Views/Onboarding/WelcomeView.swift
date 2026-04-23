import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var preferences: AppPreferencesManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()
                
                VStack(spacing: 28) {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 18) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .fill(Theme.heroGradient)
                                .frame(width: 96, height: 96)
                            
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        
                        Text(preferences.text("Добро пожаловать в Bankir", "Welcome to Bankir"))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        
                        Text(preferences.text("Сначала выбери, что тебе нужно: создать новый аккаунт или войти в уже существующий.", "Choose what you want to do first: create a new account or sign in to an existing one."))
                            .font(.body)
                            .foregroundStyle(Theme.mutedText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 14) {
                        NavigationLink {
                            RegisterView()
                        } label: {
                            Text(preferences.text("Зарегистрироваться", "Create Account"))
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .foregroundStyle(.white)
                                .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        
                        NavigationLink {
                            LoginView()
                        } label: {
                            Text(preferences.text("Войти", "Sign In"))
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .foregroundStyle(Theme.accentStrong)
                                .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppPreferencesManager.shared)
}
