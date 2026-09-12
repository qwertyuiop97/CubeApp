import AppKit
import SwiftUI
import CoreGraphics

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: FloatingOverlayWindow!
    private let stateManager = CubeStateManager()
    private var solveTimer: SolveTimer!
    private var timeStore: TimeStore!
    private var trainerStore: TrainerStore!
    private var statusItem: NSStatusItem?
    private var eventTap: CFMachPort?
    private var libraryWindowController: LibraryWindowController?
    private var armWorkItem: DispatchWorkItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Headless / accessory mode: no Dock icon, no menu bar app windows
        NSApp.setActivationPolicy(.accessory)

        // Load persisted size mode and anchor from @AppStorage / UserDefaults before creating window
        if let savedSizeRaw = UserDefaults.standard.string(forKey: UDKey.sizeMode),
           let savedSize = SizeMode(rawValue: savedSizeRaw) {
             stateManager.setSizeMode(savedSize)
         }
         if let savedAnchorRaw = UserDefaults.standard.string(forKey: UDKey.anchorPosition),
            let savedAnchor = Anchor(rawValue: savedAnchorRaw) {
             stateManager.setAnchor(savedAnchor)
         }
         if let savedFollow = UserDefaults.standard.object(forKey: UDKey.followActiveScreen) as? Bool {
             stateManager.followActiveScreen = savedFollow
         }
         if let savedPref = UserDefaults.standard.string(forKey: UDKey.preferredScreen) {
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

        trainerStore = TrainerStore()

        let rootView = ContentView()
            .environment(\.cubeStateManager, stateManager)
            .environmentObject(solveTimer)
            .environmentObject(timeStore)
            .environmentObject(trainerStore)

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

        // Reduce Motion and the keyboard take this path: same outcome, no animation.
        NotificationCenter.default.addObserver(
            forName: .requestImmediateHide,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.hideWindowImmediately()
        }

        // Global hotkey: Ctrl+Shift+Space (or saved) toggles visibility
        GlobalHotKeyManager.shared.rebindIfSaved { [weak self] in
            self?.window?.toggleVisibility()
        }

        // Listen for hotkey change requests
        NotificationCenter.default.addObserver(
            forName: .requestHotkeyRebind,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebindHotkey()
        }

        // Menu bar icon for quick toggle
        setupStatusItem()

        // Global spacebar for timer (CGEventTap) — only active when window visible + timer tab + appropriate state
        setupSpacebarEventTap()
        if eventTap == nil {
            // Accessibility permission missing — inform the HUD so it can show a prompt sheet
            NotificationCenter.default.post(name: .requestAccessibilityPrompt, object: nil)
        }

        // Listen for retry requests from the accessibility prompt
        NotificationCenter.default.addObserver(
            forName: .requestRetryEventTap,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setupSpacebarEventTap()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "cube", accessibilityDescription: "CubeNotch")
            button.toolTip = "CubeNotch – Click to toggle overlay (Ctrl+Shift+Space)"
            button.target = self
            button.action = #selector(toggleWindowFromMenu)
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Overlay", action: #selector(toggleWindowFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Library", action: #selector(openLibrary), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About CubeNotch", action: #selector(showAbout), keyEquivalent: ""))
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

    @objc private func showAbout() {
        let aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        aboutWindow.title = "About CubeNotch"
        aboutWindow.isReleasedWhenClosed = false
        aboutWindow.center()

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let aboutView = AboutView(version: version)
        aboutWindow.contentView = NSHostingView(rootView: aboutView)

        aboutWindow.makeKeyAndOrderFront(nil)
    }

    private func positionWindowUsingCurrentState(size: NSSize) {
        guard let window = window else { return }
        let anchor = stateManager.anchorPosition
        let scr = preferredOrActiveScreen()
        // Spring glide on initial show
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

    private func hideWindowImmediately() {
        solveTimer?.isTimerTabActive = false
        window?.orderOut(nil)
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
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue) | CGEventMask(1 << CGEventType.keyUp.rawValue)
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
        // Ignore key-repeat events (held key) — prevents spurious solve starts/stops
        guard event.getIntegerValueField(.keyboardEventAutorepeat) == 0 else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let spaceKeyCode: CGKeyCode = 49 // kVK_Space

        guard let w = window, w.isVisible, let t = solveTimer, t.isTimerTabActive else {
            return Unmanaged.passUnretained(event)
        }

        if keyCode == spaceKeyCode {
            if type == .keyDown {
                if t.state == .running {
                    // immediate stop on space while running (no hold required)
                    DispatchQueue.main.async { t.toggle() }
                    return nil
                }
                if t.state == .idle {
                    // start hold-to-arm: cancel any prior, schedule arm after 0.4s, consume
                    armWorkItem?.cancel()
                    let work = DispatchWorkItem { [weak self] in
                        self?.solveTimer?.arm()
                    }
                    armWorkItem = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
                    return nil
                }
                if t.isInspecting {
                    // existing inspection behavior
                    DispatchQueue.main.async { t.toggle() }
                    return nil
                }
                return Unmanaged.passUnretained(event)
            } else if type == .keyUp {
                if t.isArmed {
                    // release while armed starts the solve
                    DispatchQueue.main.async { t.startFromArm() }
                    return nil
                } else {
                    // release before 0.4s: pass through to other apps (typing etc)
                    armWorkItem?.cancel()
                    armWorkItem = nil
                    return Unmanaged.passUnretained(event)
                }
            }
        }
        return Unmanaged.passUnretained(event)
    }

    // Called when the user changes the hotkey in Settings
    private func rebindHotkey() {
        GlobalHotKeyManager.shared.rebindIfSaved { [weak self] in
            self?.window?.toggleVisibility()
        }
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
