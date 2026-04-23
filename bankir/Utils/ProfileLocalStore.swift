import Foundation

struct ProfileExtras: Codable {
    enum PreferredLanguage: String, Codable, CaseIterable, Identifiable {
        case ru = "Русский"
        case en = "English"
        
        var id: String { rawValue }
    }
    
    enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
        case system = "Системная"
        case light = "Светлая"
        case dark = "Тёмная"
        
        var id: String { rawValue }
    }
    
    var fullName: String
    var phoneNumber: String
    var city: String
    var address: String
    var ibanSuffix: String
    var avatarImageData: Data?
    var quickLoginEnabled: Bool
    var marketingEnabled: Bool
    var preferredLanguage: PreferredLanguage
    var appearanceMode: AppearanceMode
    
    static let empty = ProfileExtras(
        fullName: "",
        phoneNumber: "",
        city: "",
        address: "",
        ibanSuffix: "",
        avatarImageData: nil,
        quickLoginEnabled: false,
        marketingEnabled: false,
        preferredLanguage: .ru,
        appearanceMode: .system
    )
}

enum ProfileLocalStore {
    private static let prefix = "profileExtras."
    
    static func load(for profileID: UUID) -> ProfileExtras {
        guard
            let data = UserDefaults.standard.data(forKey: prefix + profileID.uuidString),
            let extras = try? JSONDecoder().decode(ProfileExtras.self, from: data)
        else {
            return .empty
        }
        
        return extras
    }
    
    static func save(_ extras: ProfileExtras, for profileID: UUID) {
        guard let data = try? JSONEncoder().encode(extras) else { return }
        UserDefaults.standard.set(data, forKey: prefix + profileID.uuidString)
    }
}
