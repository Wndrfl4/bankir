//
//  TabBarRootView.swift
//  bankir
//
//  Created by Aslan  on 16.04.2026.
//


import SwiftUI

struct TabBarRootView: View {
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }

            if authManager.hasAccess(to: .payments) {
                PaymentsView()
                    .tabItem {
                        Label("Платежи", systemImage: "creditcard.fill")
                    }
            }

            if authManager.hasAccess(to: .cards) {
                CardsView()
                    .tabItem {
                        Label("Карты", systemImage: "wallet.pass.fill")
                    }
            }

            if authManager.hasAccess(to: .categoriesManagement) {
                CategoriesView()
                    .tabItem {
                        Label("Категории", systemImage: "folder.fill")
                    }
            }

            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    TabBarRootView()
        .environmentObject(AuthManager.shared)
}
