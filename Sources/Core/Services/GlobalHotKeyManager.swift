import AppKit
import Carbon

/// Minimal global hotkey support for show/hide toggle.
/// Registers Option+Space by default (non-conflicting for most users).
/// Uses Carbon EventHotKey API (still supported on macOS).
public final class GlobalHotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var handler: (() -> Void)?

    // 13A-4: custom hotkey storage
    private var currentKeyCode: UInt32 = 49
    private var currentModifiers: UInt32 = UInt32(optionKey)

    public static let shared = GlobalHotKeyManager()

    private init() {}

    public func registerDefault(handler: @escaping () -> Void) {
        // Option + Space = keyCode 49 (space), modifier optionKey
        let keyCode: UInt32 = 49
        let modifiers: UInt32 = UInt32(optionKey)
        register(keyCode: keyCode, modifiers: modifiers, handler: handler)
    }

    public func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        unregister()

        currentKeyCode = keyCode
        currentModifiers = modifiers
        self.handler = handler

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType("CNHK".utf16.reduce(0) { ($0 << 8) | UInt32($1) })
        hotKeyID.id = 1

        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        guard status == noErr, hotKeyRef != nil else { return }

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = UInt32(kEventHotKeyPressed)

        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        InstallEventHandler(GetApplicationEventTarget(), { _, inEvent, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            var hkID = EventHotKeyID()
            GetEventParameter(inEvent, UInt32(kEventParamDirectObject), UInt32(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            if hkID.id == 1 {
                manager.handler?()
            }
            return noErr
        }, 1, &eventType, selfPtr, &eventHandler)
    }

    public func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        handler = nil
    }

    // 13A-4 helpers
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

    public func setHotkey(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        // Guard: Space alone is reserved for timer
        if keyCode == 49 && modifiers == 0 { return }
        // Guard: Escape / Return
        if keyCode == 53 || keyCode == 36 { return }
        register(keyCode: keyCode, modifiers: modifiers, handler: handler)
        // persist raw values
        UserDefaults.standard.set(Int(keyCode), forKey: UDKey.customHotKeyCode)
        UserDefaults.standard.set(Int(modifiers), forKey: UDKey.customHotKeyMods)
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

    // 13A-4 persisted values
    public var savedKeyCode: UInt32 {
        let v = UserDefaults.standard.integer(forKey: UDKey.customHotKeyCode)
        return v > 0 ? UInt32(v) : 49
    }

    public var savedModifiers: UInt32 {
        let v = UserDefaults.standard.integer(forKey: UDKey.customHotKeyMods)
        return v > 0 ? UInt32(v) : UInt32(optionKey)
    }

    public func rebindIfSaved(handler: @escaping () -> Void) {
        let code = UserDefaults.standard.integer(forKey: UDKey.customHotKeyCode)
        let mods = UserDefaults.standard.integer(forKey: UDKey.customHotKeyMods)
        if code > 0 {
            register(keyCode: UInt32(code), modifiers: UInt32(mods), handler: handler)
        } else {
            registerDefault(handler: handler)
        }
    }
}
