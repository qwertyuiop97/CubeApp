import Foundation
import ServiceManagement

protocol LaunchAtLoginServicing {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

struct LaunchAtLoginApplyResult: Equatable {
    var isEnabled: Bool
    var errorMessage: String?
}

struct SMAppLaunchAtLoginService: LaunchAtLoginServicing {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}

/// Manages the app’s login item.
/// Uses SMAppService (macOS 13+) for modern launch-at-login without LSUIElement hacks.
public enum LaunchAtLogin {
    private static let liveService: any LaunchAtLoginServicing = SMAppLaunchAtLoginService()

    public static var isEnabled: Bool {
        liveService.isEnabled
    }

    static func apply(_ enabled: Bool, using service: any LaunchAtLoginServicing) -> LaunchAtLoginApplyResult {
        do {
            try service.setEnabled(enabled)
            return LaunchAtLoginApplyResult(isEnabled: service.isEnabled, errorMessage: nil)
        } catch {
            return LaunchAtLoginApplyResult(
                isEnabled: service.isEnabled,
                errorMessage: "Couldn’t update launch at login."
            )
        }
    }

    static func apply(_ enabled: Bool) -> LaunchAtLoginApplyResult {
        apply(enabled, using: liveService)
    }

    @discardableResult
    public static func setEnabled(_ enabled: Bool) -> Bool {
        apply(enabled).errorMessage == nil
    }
}
