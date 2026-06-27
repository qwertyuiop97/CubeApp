import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: FloatingOverlayWindow!
    private let stateManager = CubeStateManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Headless / accessory mode: no Dock icon, no menu bar app windows
        NSApp.setActivationPolicy(.accessory)

        // Load persisted size mode and anchor from @AppStorage / UserDefaults before creating window
        if let savedSizeRaw = UserDefaults.standard.string(forKey: "sizeMode"),
           let savedSize = SizeMode(rawValue: savedSizeRaw) {
            stateManager.setSizeMode(savedSize)
        }
        if let savedAnchorRaw = UserDefaults.standard.string(forKey: "anchorPosition"),
           let savedAnchor = Anchor(rawValue: savedAnchorRaw) {
            stateManager.setAnchor(savedAnchor)
        }

        // Create the borderless floating transparent NSPanel (non-activating)
        window = FloatingOverlayWindow()

        // Host SwiftUI content
        let rootView = ContentView()
            .environment(\.cubeStateManager, stateManager)

        let hostingController = NSHostingController(rootView: rootView)
        window.contentView = hostingController.view

        // Position and show the floating window
        let initialSize = stateManager.sizeMode.windowSize
        window.positionAtAnchor(stateManager.anchorPosition, size: initialSize)
        window.makeKeyAndOrderFront(nil)

        // React to live changes from state manager (size, anchor, etc.)
        NotificationCenter.default.addObserver(
            forName: .cubeStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleStateChange()
        }
    }

    private func handleStateChange() {
        guard let window = window else { return }
        let size = stateManager.sizeMode.windowSize
        let anchor = stateManager.anchorPosition
        window.resizeTo(size, anchor: anchor)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// Environment key for injecting the shared manager
struct CubeStateManagerKey: EnvironmentKey {
    static let defaultValue: CubeStateManager = CubeStateManager()
}

extension EnvironmentValues {
    var cubeStateManager: CubeStateManager {
        get { self[CubeStateManagerKey.self] }
        set { self[CubeStateManagerKey.self] = newValue }
    }
}
