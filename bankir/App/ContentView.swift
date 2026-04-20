////
////  ContentView.swift
////  bankir
////
////  Created by Aslan  on 17.02.2026.
////

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated() {
                TabBarRootView()
                    .onTapGesture {
                        authManager.resetInactivityTimer()
                    }
            } else {
                WelcomeView()
            }
        }
        .environmentObject(authManager)
    }
}

#Preview {
    ContentView()
}
