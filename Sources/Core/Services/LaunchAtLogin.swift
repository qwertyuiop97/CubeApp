import Foundation
import ServiceManagement

/// LaunchAtLogin helper for Phase 4.
/// Uses SMAppService (macOS 13+) for modern launch-at-login without LSUIElement hacks.
public enum LaunchAtLogin {
    private static let service = SMAppService.mainApp

    public static var isEnabled: Bool {
        switch service.status {
        case .enabled: return true
        default: return false
        }
    }

    @discardableResult
    public static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            return true
        } catch {
            // Non-fatal: log in real app; for now we silently tolerate (common in dev)
            return false
        }
    }
}
