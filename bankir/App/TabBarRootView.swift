//
//  TabBarRootView.swift
//  bankir
//
//  Created by Aslan  on 16.04.2026.
//


import SwiftUI

struct TabBarRootView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var preferences: AppPreferencesManager
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(preferences.text("Главная", "Home"), systemImage: "house.fill")
                }

            if authManager.hasAccess(to: .payments) {
                PaymentsView()
                    .tabItem {
                        Label(preferences.text("Платежи", "Payments"), systemImage: "creditcard.fill")
                    }
            }

            if authManager.hasAccess(to: .cards) {
                CardsView()
                    .tabItem {
                        Label(preferences.text("Карты", "Cards"), systemImage: "wallet.pass.fill")
                    }
            }

            if authManager.hasAccess(to: .categoriesManagement) {
                CategoriesView()
                    .tabItem {
                        Label(preferences.text("Категории", "Categories"), systemImage: "folder.fill")
                    }
            }

            ProfileView()
                .tabItem {
                    Label(preferences.text("Профиль", "Profile"), systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    TabBarRootView()
        .environmentObject(AuthManager.shared)
        .environmentObject(AppPreferencesManager.shared)
}
