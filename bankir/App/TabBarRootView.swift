//
//  TabBarRootView.swift
//  bankir
//
//  Created by Aslan  on 16.04.2026.
//


import SwiftUI

struct TabBarRootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }
            PaymentsView()
                .tabItem {
                    Label("Платежи", systemImage: "creditcard.fill")
                }
            CardsView()
                .tabItem {
                    Label("Карты", systemImage: "wallet.pass.fill")
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
}