import Foundation
import UIKit

// Детекция jailbreak для повышения безопасности
class JailbreakDetection {
    static func isJailbroken() -> Bool {
        // Проверка на наличие Cydia
        if FileManager.default.fileExists(atPath: "/Applications/Cydia.app") ||
           FileManager.default.fileExists(atPath: "/Library/MobileSubstrate/MobileSubstrate.dylib") ||
           FileManager.default.fileExists(atPath: "/bin/bash") ||
           FileManager.default.fileExists(atPath: "/usr/sbin/sshd") ||
           FileManager.default.fileExists(atPath: "/etc/apt") ||
           FileManager.default.fileExists(atPath: "/private/var/lib/apt/") {
            return true
        }
        
        // Проверка на возможность записи в системные директории
        let testPath = "/private/jailbreak_test.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            // Нормально, если не можем записать
        }
        
        // Проверка на подозрительные URL схемы
        if let url = URL(string: "cydia://package/com.example.package"), UIApplication.shared.canOpenURL(url) {
            return true
        }
        
        return false
    }
    
    static func handleJailbreak() {
        // В случае jailbreak, показать предупреждение и выйти
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Security Alert", message: "This device appears to be jailbroken. For security reasons, the app cannot run.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Exit", style: .destructive) { _ in
                exit(0)
            })
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(alert, animated: true)
            }
        }
    }
}