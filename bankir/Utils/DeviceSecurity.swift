import Foundation
import DeviceCheck
import UIKit

// Защита от атак на устройство
class DeviceSecurity {
    static let shared = DeviceSecurity()
    
    // App Attest для проверки подлинности app
    func attestApp() async throws -> Bool {
        guard DCAppAttestService.shared.isSupported else {
            return false // Не поддерживается
        }
        
        let service = DCAppAttestService.shared
        let keyId = try await service.generateKey()
        
        // В реальности, отправить keyId на сервер для верификации
        // Здесь mock
        return true
    }
    
    // Проверка на подключение debugger
    func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        if result == 0 {
            return (info.kp_proc.p_flag & P_TRACED) != 0
        }
        return false
    }
    
    // Проверка на эмулятор
    func isRunningOnSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    // Общая проверка безопасности устройства
    func performSecurityChecks() -> Bool {
        if JailbreakDetection.isJailbroken() {
            return false
        }
        if isDebuggerAttached() {
            return false
        }
        if isRunningOnSimulator() {
            // Для продакшена запретить
            return false
        }
        return true
    }
}