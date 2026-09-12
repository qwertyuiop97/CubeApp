import AppKit
import XCTest
@testable import CubeNotch

final class HotkeyCaptureFocusTests: XCTestCase {
    private func offscreenOverlay() -> FloatingOverlayWindow {
        let window = FloatingOverlayWindow()
        window.setFrame(NSRect(x: -10_000, y: -10_000, width: 40, height: 40), display: false)
        window.orderOut(nil)
        return window
    }

    private func titledWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: -9_000, y: -9_000, width: 24, height: 24),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.orderOut(nil)
        return window
    }

    private func keyEvent(windowNumber: Int, keyCode: UInt16 = 0) -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [.command],
            timestamp: 0,
            windowNumber: windowNumber,
            context: nil,
            characters: "a",
            charactersIgnoringModifiers: "a",
            isARepeat: false,
            keyCode: keyCode
        )!
    }

    func testNonactivatingOverlayCannotBecomeKeyByDefault() {
        let overlay = offscreenOverlay()
        defer { overlay.close() }

        XCTAssertFalse(overlay.canBecomeKey)
        overlay.makeKey()
        XCTAssertFalse(overlay.isKeyWindow)
        XCTAssertTrue(overlay.becomesKeyOnlyIfNeeded)
    }

    func testTemporaryFocusAllowsKeyThenRestoresNonactivatingBehavior() {
        let overlay = offscreenOverlay()
        defer { overlay.close() }

        overlay.beginTemporaryKeyboardFocus()
        XCTAssertTrue(overlay.canBecomeKey)
        XCTAssertFalse(overlay.becomesKeyOnlyIfNeeded)
        overlay.orderFront(nil)
        overlay.makeKey()
        XCTAssertTrue(overlay.isKeyWindow, "Offscreen ordered-front panel can become key once canBecomeKey is true")

        overlay.endTemporaryKeyboardFocus()
        XCTAssertFalse(overlay.canBecomeKey)
        XCTAssertTrue(overlay.becomesKeyOnlyIfNeeded)
        XCTAssertFalse(overlay.isKeyWindow)
    }

    func testControllerStartRequestsFocusAndStopRestoresOnCancelPath() {
        let overlay = offscreenOverlay()
        defer { overlay.close() }

        var activated = 0
        var restored = 0
        let controller = HotkeyCaptureController(
            activateThisApp: { activated += 1 },
            restorePriorActivation: { restored += 1 }
        )

        controller.start(on: overlay) { _ in nil }

        XCTAssertTrue(controller.isCapturing)
        XCTAssertTrue(overlay.canBecomeKey)
        XCTAssertEqual(activated, 1)
        XCTAssertEqual(restored, 0)

        controller.stop()

        XCTAssertFalse(controller.isCapturing)
        XCTAssertFalse(overlay.canBecomeKey)
        XCTAssertTrue(overlay.becomesKeyOnlyIfNeeded)
        XCTAssertEqual(activated, 1)
        XCTAssertEqual(restored, 1)
    }

    func testControllerStopIsIdempotentAndRestoresAfterSuccessPath() {
        let overlay = offscreenOverlay()
        defer { overlay.close() }

        var restored = 0
        let controller = HotkeyCaptureController(restorePriorActivation: { restored += 1 })
        controller.start(on: overlay) { _ in nil }
        controller.stop()
        controller.stop()

        XCTAssertEqual(restored, 1)
        XCTAssertFalse(controller.isCapturing)
        XCTAssertFalse(overlay.canBecomeKey)
    }

    func testMonitorScopeIgnoresOtherWindowsAndNilCapture() {
        let capture = titledWindow()
        let other = titledWindow()
        defer {
            capture.close()
            other.close()
        }

        let foreign = keyEvent(windowNumber: other.windowNumber)
        let own = keyEvent(windowNumber: capture.windowNumber)
        let detached = keyEvent(windowNumber: 0)

        XCTAssertFalse(HotkeyCaptureMonitorScope.shouldHandle(foreign, captureWindow: capture))
        XCTAssertTrue(HotkeyCaptureMonitorScope.shouldHandle(own, captureWindow: capture))
        XCTAssertFalse(HotkeyCaptureMonitorScope.shouldHandle(own, captureWindow: nil))
        XCTAssertFalse(HotkeyCaptureMonitorScope.shouldHandle(detached, captureWindow: capture))
    }

    func testMonitorScopeAcceptsDetachedKeyDownOnlyWhileCaptureWindowIsKey() {
        let overlay = offscreenOverlay()
        defer { overlay.close() }
        let detached = keyEvent(windowNumber: 0)

        XCTAssertFalse(HotkeyCaptureMonitorScope.shouldHandle(detached, captureWindow: overlay))

        overlay.beginTemporaryKeyboardFocus()
        overlay.orderFront(nil)
        overlay.makeKey()
        XCTAssertTrue(overlay.isKeyWindow)
        XCTAssertTrue(HotkeyCaptureMonitorScope.shouldHandle(detached, captureWindow: overlay))

        overlay.endTemporaryKeyboardFocus()
        XCTAssertFalse(HotkeyCaptureMonitorScope.shouldHandle(detached, captureWindow: overlay))
    }
}
