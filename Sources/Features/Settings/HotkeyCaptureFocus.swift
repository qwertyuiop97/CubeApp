import AppKit

public enum HotkeyCaptureMonitorScope {
    public static func shouldHandle(_ event: NSEvent, captureWindow: NSWindow?) -> Bool {
        guard event.type == .keyDown, let captureWindow else { return false }
        if let eventWindow = event.window {
            return eventWindow === captureWindow
        }
        return captureWindow.isKeyWindow
    }
}

public final class HotkeyCaptureController {
    public private(set) var isCapturing = false

    private let activateThisApp: () -> Void
    private let restorePriorActivation: () -> Void
    private var monitor: Any?
    private weak var overlay: FloatingOverlayWindow?
    private var shouldRestoreActivation = false

    public init(
        activateThisApp: @escaping () -> Void = {},
        restorePriorActivation: @escaping () -> Void = {}
    ) {
        self.activateThisApp = activateThisApp
        self.restorePriorActivation = restorePriorActivation
    }

    public static func usingAppKit() -> HotkeyCaptureController {
        var previous: NSRunningApplication?
        return HotkeyCaptureController(
            activateThisApp: {
                previous = NSWorkspace.shared.frontmostApplication
                NSApp.activate()
            },
            restorePriorActivation: {
                defer { previous = nil }
                guard let app = previous,
                      app.processIdentifier != NSRunningApplication.current.processIdentifier else {
                    return
                }
                app.activate()
            }
        )
    }

    public func start(on overlay: FloatingOverlayWindow, handleKeyDown: @escaping (NSEvent) -> NSEvent?) {
        stop()
        self.overlay = overlay
        isCapturing = true
        overlay.beginTemporaryKeyboardFocus()
        overlay.makeKey()
        activateThisApp()
        shouldRestoreActivation = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let capture = self.overlay else { return event }
            guard HotkeyCaptureMonitorScope.shouldHandle(event, captureWindow: capture) else {
                return event
            }
            return handleKeyDown(event)
        }
    }

    public func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        overlay?.endTemporaryKeyboardFocus()
        overlay = nil
        let needsRestore = shouldRestoreActivation
        shouldRestoreActivation = false
        isCapturing = false
        if needsRestore {
            restorePriorActivation()
        }
    }
}
