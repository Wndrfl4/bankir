import SwiftUI
import Combine

@MainActor
final class AppPreferencesManager: ObservableObject {
    static let shared = AppPreferencesManager()
    
    @Published private(set) var preferredLanguage: ProfileExtras.PreferredLanguage = .ru
    @Published private(set) var appearanceMode: ProfileExtras.AppearanceMode = .system
    
    private init() {}
    
    var colorScheme: ColorScheme? {
        switch appearanceMode {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    func reload(for profileID: UUID?) {
        guard let profileID else {
            preferredLanguage = .ru
            appearanceMode = .system
            return
        }
        
        let extras = ProfileLocalStore.load(for: profileID)
        preferredLanguage = extras.preferredLanguage
        appearanceMode = extras.appearanceMode
    }
    
    func apply(language: ProfileExtras.PreferredLanguage, appearance: ProfileExtras.AppearanceMode) {
        preferredLanguage = language
        appearanceMode = appearance
    }
    
    func text(_ russian: String, _ english: String) -> String {
        preferredLanguage == .ru ? russian : english
    }
}
