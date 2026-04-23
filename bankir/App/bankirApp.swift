//
//  bankirApp.swift
//  bankir
//
//  Created by Aslan  on 17.02.2026.
//

import SwiftUI
import SwiftData

@main
struct bankirApp: App {
    init() {
        #if targetEnvironment(simulator)
        return
        #else
        #if DEBUG
        return
        #else
        // Проверка на jailbreak
        if JailbreakDetection.isJailbroken() {
            JailbreakDetection.handleJailbreak()
        }
        
        // Дополнительные проверки устройства
        if !DeviceSecurity.shared.performSecurityChecks() {
            // Блокировать app
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Security Alert", message: "Device security check failed.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Exit", style: .destructive) { _ in
                    exit(0)
                })
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController?.present(alert, animated: true)
                }
            }
        }
        
        // App Attest (асинхронно)
        Task {
            do {
                let attested = try await DeviceSecurity.shared.attestApp()
                if !attested {
                    print("App attestation failed")
                }
            } catch {
                print("Attestation error: \(error)")
            }
        }
        #endif
        #endif
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Category.self,
            Transaction.self,
            UserProfile.self,
        ])
        let modelConfiguration = ModelConfiguration("Default", schema: schema, isStoredInMemoryOnly: false, allowsSave: true, groupContainer: .none, cloudKitDatabase: .none)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            seedDefaultAccountsIfNeeded(using: container.mainContext)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
    
    private static func seedDefaultAccountsIfNeeded(using context: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>()
        let existingProfiles = (try? context.fetch(descriptor)) ?? []
        
        if !existingProfiles.contains(where: { $0.username.lowercased() == "admin" }) {
            let adminProfile = UserProfile(
                username: "admin",
                email: "admin@bankir.local",
                password: "password",
                role: .admin
            )
            context.insert(adminProfile)
        }
        
        if !existingProfiles.contains(where: { $0.username.lowercased() == "test" }) {
            let mockProfile = UserProfile(
                username: "test",
                email: "user@bankir.local",
                password: "password",
                role: .user
            )
            context.insert(mockProfile)
        }
        
        try? context.save()
    }
}
