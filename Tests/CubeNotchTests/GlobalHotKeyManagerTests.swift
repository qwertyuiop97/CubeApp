import Carbon
import XCTest
@testable import CubeNotch

final class GlobalHotKeyManagerTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var registrar: RecordingHotKeyRegistrar!
    private var manager: GlobalHotKeyManager!

    private let option = UInt32(optionKey)
    private let ctrlShift = UInt32(controlKey | shiftKey)
    private let command = UInt32(cmdKey)

    override func setUp() {
        super.setUp()
        suiteName = "cube.hotkey.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        registrar = RecordingHotKeyRegistrar()
        manager = GlobalHotKeyManager(defaults: defaults, registrar: registrar)
    }

    override func tearDown() {
        manager?.unregister()
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        manager = nil
        registrar = nil
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testRebindingSameCombinationUpdatesCallbackWithoutRegisteringAgain() {
        var oldCalls = 0
        var newCalls = 0
        XCTAssertTrue(manager.register(keyCode: 0, modifiers: command) { oldCalls += 1 })
        registrar.nextRegisterSucceeds = false // Carbon rejects duplicate key registrations.
        XCTAssertTrue(manager.register(keyCode: 0, modifiers: command) { newCalls += 1 })
        registrar.currentHandler?()
        XCTAssertEqual(oldCalls, 0)
        XCTAssertEqual(newCalls, 1)
        XCTAssertEqual(registrar.registerCalls.count, 1)
    }

    func testChangingShortcutKeepsTheExistingToggleCallback() {
        var calls = 0
        manager.registerDefault { calls += 1 }
        XCTAssertEqual(manager.setHotkey(keyCode: 0, modifiers: command), .bound)
        registrar.currentHandler?()
        XCTAssertEqual(calls, 1)
    }

    func testSavedKeyCodePreservesZeroForKeyA() {
        defaults.set(0, forKey: UDKey.customHotKeyCode)

        XCTAssertEqual(manager.savedKeyCode, 0)
    }

    func testSavedKeyCodeFallsBackWhenMissing() {
        XCTAssertEqual(manager.savedKeyCode, 49)
    }

    func testSavedModifiersPreservesLegitimateZero() {
        defaults.set(0, forKey: UDKey.customHotKeyMods)

        XCTAssertEqual(manager.savedModifiers, 0)
    }

    func testSavedModifiersFallsBackWhenMissing() {
        XCTAssertEqual(manager.savedModifiers, ctrlShift)
    }

    func testSavedKeyCodeDoesNotTrapOnNegativeOrOversizedValues() {
        defaults.set(-1, forKey: UDKey.customHotKeyCode)
        XCTAssertEqual(manager.savedKeyCode, 49)

        defaults.set(Int(UInt32.max) + 1, forKey: UDKey.customHotKeyCode)
        XCTAssertEqual(manager.savedKeyCode, 49)
    }

    func testSavedModifiersDoesNotTrapOnNegativeOrOversizedValues() {
        defaults.set(-8, forKey: UDKey.customHotKeyMods)
        XCTAssertEqual(manager.savedModifiers, ctrlShift)

        defaults.set(Int(UInt32.max) + 1, forKey: UDKey.customHotKeyMods)
        XCTAssertEqual(manager.savedModifiers, ctrlShift)
    }

    func testRebindIfSavedRegistersKeyAWithZeroKeyCode() {
        defaults.set(0, forKey: UDKey.customHotKeyCode)
        defaults.set(Int(option), forKey: UDKey.customHotKeyMods)

        manager.rebindIfSaved { }

        XCTAssertEqual(registrar.current?.keyCode, 0)
        XCTAssertEqual(registrar.current?.modifiers, option)
    }

    func testRebindIfSavedUsesDefaultWhenNothingSaved() {
        manager.rebindIfSaved { }

        XCTAssertEqual(registrar.current?.keyCode, 49)
        XCTAssertEqual(registrar.current?.modifiers, ctrlShift)
    }

    func testRebindIfSavedFallsBackToDefaultWhenStoredValuesAreCorrupt() {
        defaults.set(-1, forKey: UDKey.customHotKeyCode)
        defaults.set(Int(UInt32.max) + 1, forKey: UDKey.customHotKeyMods)

        manager.rebindIfSaved { }

        XCTAssertEqual(registrar.current?.keyCode, 49)
        XCTAssertEqual(registrar.current?.modifiers, ctrlShift)
    }

    func testSetHotkeyRejectsSpaceAloneWithoutPersistingOrRegistering() {
        let result = manager.setHotkey(keyCode: 49, modifiers: 0, handler: {})

        XCTAssertEqual(result, .rejectedUnsafeCombo)
        XCTAssertNil(defaults.object(forKey: UDKey.customHotKeyCode))
        XCTAssertNil(defaults.object(forKey: UDKey.customHotKeyMods))
        XCTAssertTrue(registrar.registerCalls.isEmpty)
    }

    func testSetHotkeyRejectsEscapeAndReturnWithoutPersisting() {
        XCTAssertEqual(manager.setHotkey(keyCode: 53, modifiers: command, handler: {}), .rejectedUnsafeCombo)
        XCTAssertEqual(manager.setHotkey(keyCode: 36, modifiers: command, handler: {}), .rejectedUnsafeCombo)
        XCTAssertNil(defaults.object(forKey: UDKey.customHotKeyCode))
        XCTAssertTrue(registrar.registerCalls.isEmpty)
    }

    func testSetHotkeyPersistsSuccessfulBindingIncludingKeyA() {
        let result = manager.setHotkey(keyCode: 0, modifiers: command, handler: {})

        XCTAssertEqual(result, .bound)
        XCTAssertEqual(defaults.integer(forKey: UDKey.customHotKeyCode), 0)
        XCTAssertEqual(defaults.integer(forKey: UDKey.customHotKeyMods), Int(command))
        XCTAssertEqual(registrar.current?.keyCode, 0)
        XCTAssertEqual(registrar.current?.modifiers, command)
        XCTAssertEqual(manager.currentHotkeyDisplay(), "⌘A")
    }

    func testSetHotkeyDoesNotPersistOrDropOldBindingWhenRegistrationFails() {
        XCTAssertEqual(manager.setHotkey(keyCode: 8, modifiers: command, handler: {}), .bound)
        XCTAssertEqual(defaults.integer(forKey: UDKey.customHotKeyCode), 8)

        registrar.nextRegisterSucceeds = false
        let result = manager.setHotkey(keyCode: 0, modifiers: option, handler: {})

        XCTAssertEqual(result, .registrationFailed)
        XCTAssertEqual(defaults.integer(forKey: UDKey.customHotKeyCode), 8)
        XCTAssertEqual(defaults.integer(forKey: UDKey.customHotKeyMods), Int(command))
        XCTAssertEqual(registrar.current?.keyCode, 8)
        XCTAssertEqual(registrar.current?.modifiers, command)
        XCTAssertEqual(manager.currentHotkeyDisplay(), "⌘C")
    }

    func testRegisterFailurePreservesPreviousUsableBinding() {
        manager.register(keyCode: 49, modifiers: ctrlShift, handler: {})
        XCTAssertEqual(registrar.current?.keyCode, 49)
        let unregistersAfterBind = registrar.unregisterCount

        registrar.nextRegisterSucceeds = false
        manager.register(keyCode: 0, modifiers: option, handler: {})

        XCTAssertEqual(registrar.current?.keyCode, 49)
        XCTAssertEqual(registrar.current?.modifiers, ctrlShift)
        XCTAssertEqual(registrar.unregisterCount, unregistersAfterBind)
        XCTAssertEqual(manager.currentHotkeyDisplay().contains("Space"), true)
    }

    func testRebindIfSavedFallsBackToDefaultWhenSavedComboFailsToRegister() {
        defaults.set(0, forKey: UDKey.customHotKeyCode)
        defaults.set(Int(command), forKey: UDKey.customHotKeyMods)
        registrar.nextRegisterSucceeds = false
        registrar.succeedOnCall = 2

        manager.rebindIfSaved { }

        XCTAssertEqual(registrar.current?.keyCode, 49)
        XCTAssertEqual(registrar.current?.modifiers, ctrlShift)
    }

    func testHandlerInstallFailureDoesNotRegisterOrPersist() {
        let api = RecordingCarbonHotKeyAPI()
        api.installStatus = -1
        let carbon = CarbonHotKeyRegistrar(api: api)
        manager = GlobalHotKeyManager(defaults: defaults, registrar: carbon)

        XCTAssertFalse(carbon.register(keyCode: 0, modifiers: command, handler: {}))
        XCTAssertEqual(carbon.activeHotKeyID, 0)
        XCTAssertTrue(api.liveHotKeyBits.isEmpty)
        XCTAssertEqual(manager.setHotkey(keyCode: 0, modifiers: command, handler: {}), .registrationFailed)
        XCTAssertNil(defaults.object(forKey: UDKey.customHotKeyCode))
        XCTAssertNil(defaults.object(forKey: UDKey.customHotKeyMods))
    }

    func testReplacementKeepsOldBindingWhenNewCarbonRegisterFails() {
        let api = RecordingCarbonHotKeyAPI()
        let carbon = CarbonHotKeyRegistrar(api: api)
        var firstCalls = 0
        var secondCalls = 0
        XCTAssertTrue(carbon.register(keyCode: 8, modifiers: command) { firstCalls += 1 })
        let firstID = carbon.activeHotKeyID
        api.registerStatus = OSStatus(eventHotKeyExistsErr)

        XCTAssertFalse(carbon.register(keyCode: 0, modifiers: option) { secondCalls += 1 })
        XCTAssertEqual(carbon.activeHotKeyID, firstID)
        XCTAssertEqual(api.liveHotKeyBits.count, 1)

        api.parameterID = EventHotKeyID(signature: CarbonHotKeyRegistrar.signature, id: firstID)
        XCTAssertEqual(carbon.handleHotKeyEvent(nil), noErr)
        XCTAssertEqual(firstCalls, 1)
        XCTAssertEqual(secondCalls, 0)
    }

    func testReplacementUsesUniqueIDsAndIgnoresStaleOrForeignEvents() {
        let api = RecordingCarbonHotKeyAPI()
        let carbon = CarbonHotKeyRegistrar(api: api)
        var calls = 0
        XCTAssertTrue(carbon.register(keyCode: 8, modifiers: command) { calls += 1 })
        let firstID = carbon.activeHotKeyID
        XCTAssertTrue(carbon.register(keyCode: 0, modifiers: option) { calls += 1 })
        let secondID = carbon.activeHotKeyID

        XCTAssertEqual(api.registerCalls.map(\.id.id), [firstID, secondID])
        XCTAssertNotEqual(firstID, secondID)
        XCTAssertEqual(api.liveHotKeyBits.count, 1)

        api.parameterID = EventHotKeyID(signature: CarbonHotKeyRegistrar.signature, id: firstID)
        XCTAssertEqual(carbon.handleHotKeyEvent(nil), OSStatus(eventNotHandledErr))
        XCTAssertEqual(calls, 0)

        api.parameterID = EventHotKeyID(signature: OSType("TEST".utf16.reduce(0) { ($0 << 8) | UInt32($1) }), id: secondID)
        XCTAssertEqual(carbon.handleHotKeyEvent(nil), OSStatus(eventNotHandledErr))

        api.parameterID = EventHotKeyID(signature: CarbonHotKeyRegistrar.signature, id: secondID)
        XCTAssertEqual(carbon.handleHotKeyEvent(nil), noErr)
        XCTAssertEqual(calls, 1)
    }

    func testMalformedAndNilUserDataEventsReturnEventNotHandledErr() {
        let api = RecordingCarbonHotKeyAPI()
        let carbon = CarbonHotKeyRegistrar(api: api)
        var calls = 0
        XCTAssertTrue(carbon.register(keyCode: 0, modifiers: command) { calls += 1 })

        api.getParameterStatus = -1
        api.parameterID = EventHotKeyID(signature: CarbonHotKeyRegistrar.signature, id: carbon.activeHotKeyID)
        XCTAssertEqual(carbon.handleHotKeyEvent(nil), OSStatus(eventNotHandledErr))
        XCTAssertEqual(CarbonHotKeyRegistrar.handleEvent(nil, userData: nil), OSStatus(eventNotHandledErr))
        XCTAssertEqual(calls, 0)
    }

    func testDeinitUnregistersPassUnretainedCarbonState() {
        let api = RecordingCarbonHotKeyAPI()
        var registrar: CarbonHotKeyRegistrar? = CarbonHotKeyRegistrar(api: api)
        XCTAssertTrue(registrar!.register(keyCode: 0, modifiers: command, handler: {}))
        XCTAssertFalse(api.liveHotKeyBits.isEmpty)
        XCTAssertEqual(api.installCount, 1)

        registrar = nil

        XCTAssertEqual(api.unregisterCount, 1)
        XCTAssertEqual(api.removeHandlerCount, 1)
        XCTAssertTrue(api.liveHotKeyBits.isEmpty)
    }

    func testLiveCarbonDuplicateSignatureAndIDIsAllowedForDifferentCombos() throws {
        let signature = CarbonHotKeyRegistrar.signature
        let mods = UInt32(controlKey | optionKey | shiftKey | cmdKey)
        var first: EventHotKeyRef?
        var second: EventHotKeyRef?
        let firstID = EventHotKeyID(signature: signature, id: 1)
        let secondID = EventHotKeyID(signature: signature, id: 1)
        let firstStatus = RegisterEventHotKey(50, mods, firstID, GetApplicationEventTarget(), 0, &first)
        let secondStatus = RegisterEventHotKey(51, mods, secondID, GetApplicationEventTarget(), 0, &second)
        defer {
            if let first { _ = UnregisterEventHotKey(first) }
            if let second { _ = UnregisterEventHotKey(second) }
        }
        try XCTSkipIf(firstStatus != noErr, "Carbon RegisterEventHotKey unavailable in this environment")
        XCTAssertEqual(secondStatus, noErr, "duplicate signature+id did not fail for a different combo")
        XCTAssertNotNil(second)
    }

    func testLiveCarbonRejectsDuplicateComboIndependentOfHotKeyID() throws {
        let signature = CarbonHotKeyRegistrar.signature
        let mods = UInt32(controlKey | optionKey | shiftKey | cmdKey)
        var first: EventHotKeyRef?
        var second: EventHotKeyRef?
        let firstID = EventHotKeyID(signature: signature, id: 7)
        let secondID = EventHotKeyID(signature: signature, id: 8)
        let firstStatus = RegisterEventHotKey(52, mods, firstID, GetApplicationEventTarget(), 0, &first)
        let secondStatus = RegisterEventHotKey(52, mods, secondID, GetApplicationEventTarget(), 0, &second)
        defer {
            if let first { _ = UnregisterEventHotKey(first) }
            if let second { _ = UnregisterEventHotKey(second) }
        }
        try XCTSkipIf(firstStatus != noErr, "Carbon RegisterEventHotKey unavailable in this environment")
        XCTAssertEqual(secondStatus, OSStatus(eventHotKeyExistsErr))
        XCTAssertNil(second)
    }

    func testLiveRegistrarReplacementPreservesOldComboWhenNewComboAlreadyTaken() throws {
        let mods = UInt32(controlKey | optionKey | shiftKey | cmdKey)
        var blocker: EventHotKeyRef?
        let blockerStatus = RegisterEventHotKey(
            47,
            mods,
            EventHotKeyID(signature: OSType("BLK1".utf16.reduce(0) { ($0 << 8) | UInt32($1) }), id: 1),
            GetApplicationEventTarget(),
            0,
            &blocker
        )
        defer {
            if let blocker { _ = UnregisterEventHotKey(blocker) }
        }
        try XCTSkipIf(blockerStatus != noErr, "Carbon RegisterEventHotKey unavailable in this environment")

        let registrar = CarbonHotKeyRegistrar()
        var firstCalls = 0
        var secondCalls = 0
        XCTAssertTrue(registrar.register(keyCode: 43, modifiers: mods) { firstCalls += 1 })
        XCTAssertFalse(registrar.register(keyCode: 47, modifiers: mods) { secondCalls += 1 })
        XCTAssertEqual(registrar.activeHotKeyID, 1)
        registrar.unregister()
        XCTAssertEqual(firstCalls, 0)
        XCTAssertEqual(secondCalls, 0)
    }
}

final class RecordingHotKeyRegistrar: HotKeyRegistrationSeam {
    var nextRegisterSucceeds = true
    var succeedOnCall: Int?
    private(set) var current: (keyCode: UInt32, modifiers: UInt32)?
    private(set) var registerCalls: [(keyCode: UInt32, modifiers: UInt32)] = []
    private(set) var unregisterCount = 0
    private(set) var currentHandler: (() -> Void)?

    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) -> Bool {
        registerCalls.append((keyCode, modifiers))
        let shouldSucceed: Bool
        if let succeedOnCall {
            shouldSucceed = registerCalls.count >= succeedOnCall
        } else {
            shouldSucceed = nextRegisterSucceeds
        }
        guard shouldSucceed else { return false }
        current = (keyCode, modifiers)
        currentHandler = handler
        return true
    }

    func unregister() {
        unregisterCount += 1
        current = nil
    }
}

final class RecordingCarbonHotKeyAPI: CarbonHotKeyAPI {
    var registerStatus: OSStatus = noErr
    var installStatus: OSStatus = noErr
    var getParameterStatus: OSStatus = noErr
    var parameterID = EventHotKeyID()
    private(set) var registerCalls: [(keyCode: UInt32, modifiers: UInt32, id: EventHotKeyID)] = []
    private(set) var unregisterCount = 0
    private(set) var installCount = 0
    private(set) var removeHandlerCount = 0
    private(set) var liveHotKeyBits: Set<UInt> = []
    private var nextBit: UInt = 1

    func registerEventHotKey(keyCode: UInt32, modifiers: UInt32, hotKeyID: EventHotKeyID) -> (OSStatus, EventHotKeyRef?) {
        registerCalls.append((keyCode, modifiers, hotKeyID))
        guard registerStatus == noErr else { return (registerStatus, nil) }
        let bit = nextBit
        nextBit += 1
        liveHotKeyBits.insert(bit)
        return (noErr, OpaquePointer(bitPattern: bit))
    }

    func unregisterEventHotKey(_ hotKeyRef: EventHotKeyRef) {
        unregisterCount += 1
        liveHotKeyBits.remove(UInt(bitPattern: hotKeyRef))
    }

    func installEventHandler(userData: UnsafeMutableRawPointer?) -> (OSStatus, EventHandlerRef?) {
        installCount += 1
        guard installStatus == noErr else { return (installStatus, nil) }
        return (noErr, OpaquePointer(bitPattern: 0xE1))
    }

    func removeEventHandler(_ handlerRef: EventHandlerRef) {
        _ = handlerRef
        removeHandlerCount += 1
    }

    func eventHotKeyID(from event: EventRef?) -> (OSStatus, EventHotKeyID) {
        _ = event
        return (getParameterStatus, parameterID)
    }
}
