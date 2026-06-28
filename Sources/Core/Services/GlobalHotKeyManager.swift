import AppKit
import Carbon

/// Minimal global hotkey support for show/hide toggle.
/// Registers Option+Space by default (non-conflicting for most users).
/// Uses Carbon EventHotKey API (still supported on macOS).
public final class GlobalHotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var handler: (() -> Void)?

    public static let shared = GlobalHotKeyManager()

    private init() {}

    public func registerDefault(handler: @escaping () -> Void) {
        // Option + Space = keyCode 49 (space), modifier cmdKey | optionKey | shiftKey | controlKey
        // We use optionKey (1 << 11 in Carbon)
        let keyCode: UInt32 = 49 // kVK_Space
        let modifiers: UInt32 = UInt32(optionKey)
        register(keyCode: keyCode, modifiers: modifiers, handler: handler)
    }

    public func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        unregister()

        self.handler = handler

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType("CNHK".utf16.reduce(0) { ($0 << 8) | UInt32($1) }) // 'CNHK'
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
}
