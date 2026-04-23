////
////  ContentView.swift
////  bankir
////
////  Created by Aslan  on 17.02.2026.
////

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var preferences = AppPreferencesManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                TabBarRootView()
                    .onTapGesture {
                        authManager.resetInactivityTimer()
                    }
            } else {
                WelcomeView()
            }
        }
        .preferredColorScheme(preferences.colorScheme)
        .onAppear {
            preferences.reload(for: authManager.currentProfileID)
        }
        .onChange(of: authManager.currentProfileID) { profileID in
            preferences.reload(for: profileID)
        }
        .environmentObject(authManager)
        .environmentObject(preferences)
    }
}

#Preview {
    ContentView()
}
