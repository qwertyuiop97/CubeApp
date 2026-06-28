import AppKit
import SwiftUI
import CoreGraphics

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: FloatingOverlayWindow!
    private let stateManager = CubeStateManager()
    private var solveTimer: SolveTimer!
    private var timeStore: TimeStore!
    private var statusItem: NSStatusItem?
    private var eventTap: CFMachPort?
    private var libraryWindowController: LibraryWindowController?

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
        if let savedFollow = UserDefaults.standard.object(forKey: "followActiveScreen") as? Bool {
            stateManager.followActiveScreen = savedFollow
        }
        if let savedPref = UserDefaults.standard.string(forKey: "preferredScreen") {
            stateManager.setPreferredScreenName(savedPref)
        }

        // Create the borderless floating transparent NSPanel (non-activating)
        window = FloatingOverlayWindow()

        // Host SwiftUI content
        solveTimer = SolveTimer()

        timeStore = TimeStore()
        solveTimer.onSolveFinished = { [weak self] time, scramble, penalty in
            self?.timeStore.addSolve(time: time, scramble: scramble, penalty: penalty)
        }

        let rootView = ContentView()
            .environment(\.cubeStateManager, stateManager)
            .environmentObject(solveTimer)
            .environmentObject(timeStore)

        let hostingController = NSHostingController(rootView: rootView)
        window.contentView = hostingController.view

        // Position and show the floating window
        let initialSize = stateManager.sizeMode.windowSize
        positionWindowUsingCurrentState(size: initialSize)
        window.makeKeyAndOrderFront(nil)

        // React to live changes from state manager (size, anchor, etc.)
        NotificationCenter.default.addObserver(
            forName: .cubeStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleStateChange()
        }

        // Spring-animated hide on double-click from ContentView
        NotificationCenter.default.addObserver(
            forName: .requestAnimatedHide,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.animatedHideWindow()
        }

        // Global hotkey: Option+Space toggles visibility
        GlobalHotKeyManager.shared.registerDefault { [weak self] in
            self?.window?.toggleVisibility()
        }

        // Menu bar icon for quick toggle
        setupStatusItem()

        // Global spacebar for timer (CGEventTap) — only active when window visible + timer tab + appropriate state
        setupSpacebarEventTap()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "cube", accessibilityDescription: "CubeNotch")
            button.toolTip = "CubeNotch – Click to toggle overlay (Option+Space)"
            button.target = self
            button.action = #selector(toggleWindowFromMenu)
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Overlay", action: #selector(toggleWindowFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Library", action: #selector(openLibrary), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: "Quit CubeNotch", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem?.menu = menu
    }

    @objc private func toggleWindowFromMenu() {
        animatedToggleWindow()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    @objc private func openLibrary() {
        if libraryWindowController == nil {
            libraryWindowController = LibraryWindowController()
        }
        libraryWindowController?.showWindow(nil)
        libraryWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    private func positionWindowUsingCurrentState(size: NSSize) {
        guard let window = window else { return }
        let anchor = stateManager.anchorPosition
        let scr = preferredOrActiveScreen()
        // Spring glide on initial show (Phase 5A)
        window.animatedShowTo(anchor: anchor, size: size, screen: scr)
    }

    private func preferredOrActiveScreen() -> NSScreen? {
        if !stateManager.preferredScreenName.isEmpty {
            return NSScreen.screens.first { $0.localizedName == stateManager.preferredScreenName } ?? getActiveScreen()
        }
        if stateManager.followActiveScreen {
            return getActiveScreen()
        }
        return NSScreen.main
    }

    private func getActiveScreen() -> NSScreen? {
        // Prefer screen under mouse cursor, fall back to main
        let mouseLoc = NSEvent.mouseLocation
        for screen in NSScreen.screens {
            if NSPointInRect(mouseLoc, screen.frame) {
                return screen
            }
        }
        return NSScreen.main
    }

    private func handleStateChange() {
        guard let window = window else { return }
        let size = stateManager.sizeMode.windowSize
        let anchor = stateManager.anchorPosition
        let scr = preferredOrActiveScreen()
        // Use spring glide on resize/anchor change as well
        window.animatedShowTo(anchor: anchor, size: size, screen: scr)
    }

    private func animatedHideWindow() {
        solveTimer?.isTimerTabActive = false
        guard let window = window else { return }
        let anchor = stateManager.anchorPosition
        let size = stateManager.sizeMode.windowSize
        let scr = stateManager.followActiveScreen ? getActiveScreen() : nil
        window.animatedHideTo(anchor: anchor, size: size, screen: scr)
    }

    private func animatedToggleWindow() {
        guard let w = window else { return }
        if w.isVisible {
            solveTimer?.isTimerTabActive = false
            let anchor = stateManager.anchorPosition
            let size = stateManager.sizeMode.windowSize
            let scr = stateManager.followActiveScreen ? getActiveScreen() : nil
            w.animatedHideTo(anchor: anchor, size: size, screen: scr)
        } else {
            let size = stateManager.sizeMode.windowSize
            let scr = preferredOrActiveScreen()
            w.animatedShowTo(anchor: stateManager.anchorPosition, size: size, screen: scr)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
    }

    private func setupSpacebarEventTap() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let app = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()
                return app.handleKeyEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )

        if let tap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }

    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Only act on key down
        guard type == .keyDown else { return Unmanaged.passUnretained(event) }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let spaceKeyCode: CGKeyCode = 49 // kVK_Space

        if keyCode == spaceKeyCode {
            // Only consume if window visible + timer tab active + (idle or running)
            guard let w = window, w.isVisible, let t = solveTimer, t.isTimerTabActive else {
                return Unmanaged.passUnretained(event)
            }
            if t.state == .idle || t.state == .running {
                // Dispatch toggle on main to keep UI safe
                DispatchQueue.main.async { t.toggle() }
                // Swallow the space event so it doesn't type elsewhere
                return nil
            }
        }
        return Unmanaged.passUnretained(event)
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
