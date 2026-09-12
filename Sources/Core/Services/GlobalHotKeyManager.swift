import AppKit
import Carbon

public enum HotKeyBindResult: Equatable {
    case bound
    case rejectedUnsafeCombo
    case registrationFailed
}

protocol HotKeyRegistrationSeam: AnyObject {
    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) -> Bool
    func unregister()
}

/// Injectable Carbon primitives so registrar failure paths can be tested without a full event loop.
protocol CarbonHotKeyAPI: AnyObject {
    func registerEventHotKey(keyCode: UInt32, modifiers: UInt32, hotKeyID: EventHotKeyID) -> (OSStatus, EventHotKeyRef?)
    func unregisterEventHotKey(_ hotKeyRef: EventHotKeyRef)
    func installEventHandler(userData: UnsafeMutableRawPointer?) -> (OSStatus, EventHandlerRef?)
    func removeEventHandler(_ handlerRef: EventHandlerRef)
    func eventHotKeyID(from event: EventRef?) -> (OSStatus, EventHotKeyID)
}

final class LiveCarbonHotKeyAPI: CarbonHotKeyAPI {
    func registerEventHotKey(keyCode: UInt32, modifiers: UInt32, hotKeyID: EventHotKeyID) -> (OSStatus, EventHotKeyRef?) {
        var newRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &newRef
        )
        guard status == noErr else { return (status, nil) }
        return (status, newRef)
    }

    func unregisterEventHotKey(_ hotKeyRef: EventHotKeyRef) {
        _ = UnregisterEventHotKey(hotKeyRef)
    }

    func installEventHandler(userData: UnsafeMutableRawPointer?) -> (OSStatus, EventHandlerRef?) {
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = UInt32(kEventHotKeyPressed)
        var handlerRef: EventHandlerRef?
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, inEvent, userData -> OSStatus in
                CarbonHotKeyRegistrar.handleEvent(inEvent, userData: userData)
            },
            1,
            &eventType,
            userData,
            &handlerRef
        )
        return (status, handlerRef)
    }

    func removeEventHandler(_ handlerRef: EventHandlerRef) {
        _ = RemoveEventHandler(handlerRef)
    }

    func eventHotKeyID(from event: EventRef?) -> (OSStatus, EventHotKeyID) {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            UInt32(kEventParamDirectObject),
            UInt32(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        return (status, hotKeyID)
    }
}

/// Carbon EventHotKey registration. Unit tests inject a fake seam instead.
final class CarbonHotKeyRegistrar: HotKeyRegistrationSeam {
    static let signature: OSType = OSType("CNHK".utf16.reduce(0) { ($0 << 8) | UInt32($1) })

    private let api: CarbonHotKeyAPI
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var handler: (() -> Void)?
    private var nextHotKeyID: UInt32 = 1
    private(set) var activeHotKeyID: UInt32 = 0

    init(api: CarbonHotKeyAPI = LiveCarbonHotKeyAPI()) {
        self.api = api
    }

    deinit {
        unregister()
    }

    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) -> Bool {
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: nextHotKeyID)
        let (status, newRef) = api.registerEventHotKey(keyCode: keyCode, modifiers: modifiers, hotKeyID: hotKeyID)
        guard status == noErr, let newRef else { return false }

        let previousRef = hotKeyRef
        let previousID = activeHotKeyID
        let previousHandler = self.handler
        hotKeyRef = newRef
        activeHotKeyID = hotKeyID.id
        self.handler = handler

        guard installHandlerIfNeeded() else {
            api.unregisterEventHotKey(newRef)
            hotKeyRef = previousRef
            activeHotKeyID = previousID
            self.handler = previousHandler
            return false
        }

        if let previousRef {
            api.unregisterEventHotKey(previousRef)
        }
        nextHotKeyID &+= 1
        if nextHotKeyID == 0 { nextHotKeyID = 1 }
        return true
    }

    func unregister() {
        if let hotKeyRef {
            api.unregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler {
            api.removeEventHandler(eventHandler)
            self.eventHandler = nil
        }
        handler = nil
        activeHotKeyID = 0
    }

    static func handleEvent(_ inEvent: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
        guard let userData else { return OSStatus(eventNotHandledErr) }
        let registrar = Unmanaged<CarbonHotKeyRegistrar>.fromOpaque(userData).takeUnretainedValue()
        return registrar.handleHotKeyEvent(inEvent)
    }

    func handleHotKeyEvent(_ inEvent: EventRef?) -> OSStatus {
        let (status, hotKeyID) = api.eventHotKeyID(from: inEvent)
        guard status == noErr else { return OSStatus(eventNotHandledErr) }
        guard hotKeyID.signature == Self.signature, hotKeyID.id == activeHotKeyID else {
            return OSStatus(eventNotHandledErr)
        }
        handler?()
        return noErr
    }

    private func installHandlerIfNeeded() -> Bool {
        guard eventHandler == nil else { return true }
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let (status, handlerRef) = api.installEventHandler(userData: selfPtr)
        guard status == noErr, let handlerRef else {
            eventHandler = nil
            return false
        }
        eventHandler = handlerRef
        return true
    }
}

/// Minimal global hotkey support for show/hide toggle.
/// Registers Ctrl+Shift+Space by default (avoids Alfred/Raycast conflicts).
/// Uses Carbon EventHotKey API (still supported on macOS).
public final class GlobalHotKeyManager {
    private var handler: (() -> Void)?
    private var isRegistered = false

    // Custom hotkey storage
    private var currentKeyCode: UInt32 = 49
    private var currentModifiers: UInt32 = UInt32(optionKey)

    private let defaults: UserDefaults
    private let registrar: HotKeyRegistrationSeam

    public static let shared = GlobalHotKeyManager()

    init(defaults: UserDefaults = .standard, registrar: HotKeyRegistrationSeam = CarbonHotKeyRegistrar()) {
        self.defaults = defaults
        self.registrar = registrar
    }

    public func registerDefault(handler: @escaping () -> Void) {
        // Ctrl+Shift + Space = keyCode 49 (space), modifier controlKey | shiftKey
        let keyCode: UInt32 = 49
        let modifiers: UInt32 = UInt32(controlKey | shiftKey)
        register(keyCode: keyCode, modifiers: modifiers, handler: handler)
    }

    @discardableResult
    public func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) -> Bool {
        if isRegistered, currentKeyCode == keyCode, currentModifiers == modifiers {
            self.handler = handler
            return true
        }
        guard registrar.register(keyCode: keyCode, modifiers: modifiers, handler: { [weak self] in self?.handler?() }) else {
            return false
        }
        isRegistered = true
        currentKeyCode = keyCode
        currentModifiers = modifiers
        self.handler = handler
        return true
    }

    public func unregister() {
        registrar.unregister()
        isRegistered = false
        handler = nil
    }

    // Shortcut settings
    public func currentHotkeyDisplay() -> String {
        let mod = currentModifiers
        var parts: [String] = []
        if (mod & UInt32(cmdKey)) != 0 { parts.append("⌘") }
        if (mod & UInt32(optionKey)) != 0 { parts.append("⌥") }
        if (mod & UInt32(shiftKey)) != 0 { parts.append("⇧") }
        if (mod & UInt32(controlKey)) != 0 { parts.append("⌃") }
        let keyName = keyCodeToString(currentKeyCode)
        return parts.joined() + keyName
    }

    @discardableResult
    public func setHotkey(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) -> HotKeyBindResult {
        guard !Self.isUnsafeCombo(keyCode: keyCode, modifiers: modifiers) else {
            return .rejectedUnsafeCombo
        }
        guard register(keyCode: keyCode, modifiers: modifiers, handler: handler) else {
            return .registrationFailed
        }
        defaults.set(Int(keyCode), forKey: UDKey.customHotKeyCode)
        defaults.set(Int(modifiers), forKey: UDKey.customHotKeyMods)
        return .bound
    }

    /// Settings can change the key without replacing AppDelegate's toggle action.
    @discardableResult
    public func setHotkey(keyCode: UInt32, modifiers: UInt32) -> HotKeyBindResult {
        setHotkey(keyCode: keyCode, modifiers: modifiers, handler: handler ?? {})
    }

    private func keyCodeToString(_ code: UInt32) -> String {
        // minimal mapping for common keys
        switch code {
        case 49: return "Space"
        case 53: return "⎋"
        case 36: return "⏎"
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        default: return "K\(code)"
        }
    }

    // Persisted values
    public var savedKeyCode: UInt32 {
        unsigned32(forKey: UDKey.customHotKeyCode) ?? 49
    }

    public var savedModifiers: UInt32 {
        unsigned32(forKey: UDKey.customHotKeyMods) ?? UInt32(controlKey | shiftKey)
    }

    public func rebindIfSaved(handler: @escaping () -> Void) {
        guard let code = unsigned32(forKey: UDKey.customHotKeyCode) else {
            registerDefault(handler: handler)
            return
        }
        let mods = unsigned32(forKey: UDKey.customHotKeyMods) ?? UInt32(controlKey | shiftKey)
        if Self.isUnsafeCombo(keyCode: code, modifiers: mods)
            || !register(keyCode: code, modifiers: mods, handler: handler) {
            registerDefault(handler: handler)
        }
    }

    private func unsigned32(forKey key: String) -> UInt32? {
        guard let object = defaults.object(forKey: key) else { return nil }
        let value: Int
        if let intValue = object as? Int {
            value = intValue
        } else if let number = object as? NSNumber {
            value = number.intValue
        } else {
            return nil
        }
        guard value >= 0, value <= Int(UInt32.max) else { return nil }
        return UInt32(value)
    }

    private static func isUnsafeCombo(keyCode: UInt32, modifiers: UInt32) -> Bool {
        // Guard: Space alone is reserved for timer
        if keyCode == 49 && modifiers == 0 { return true }
        // Guard: Escape / Return
        if keyCode == 53 || keyCode == 36 { return true }
        return false
    }
}
