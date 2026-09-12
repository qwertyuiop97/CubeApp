# Hotkey capture focus verification

## Question
Can Settings “Change…” record a combo on the nonactivating HUD, without making ordinary HUD display activating?

## Source / AppKit evidence
- `FloatingOverlayWindow` is `NSPanel` with `.nonactivatingPanel` and `becomesKeyOnlyIfNeeded = true`.
- Direct AppKit probe (`NSPanel` same style mask): `canBecomeKey == false`, `makeKey()` leaves `isKeyWindow == false`.
- `NSEvent.addLocalMonitorForEvents` only sees keyDown events dispatched to this app. If the panel cannot become key and CubeNotch stays inactive, the combo never arrives.
- After overriding `canBecomeKey` to true for the same style mask, offscreen `makeKey()` can set `isKeyWindow == true` **when the panel is ordered front**. Ordered-out panels stay non-key.

This matches the review hypothesis from source inspection. It was **not** reproduced with interactive foreground typing, global synthetic events, or Accessibility preference changes.

## Intended behavior
- Idle HUD: `canBecomeKey == false`, `becomesKeyOnlyIfNeeded == true` (unchanged nonactivating HUD).
- Explicit **Change…** only: temporary key focus + `NSApp.activate()`, local keyDown monitor scoped to that overlay.
- Cancel (Escape / Cancel / settings close / view disappear) and success (`setHotkey` bound) restore nonactivating behavior and yield activation back when another app was frontmost.
- Events for other windows (Library, About) are not consumed.

## Coverage (offscreen unit, not interactive capture)

| Path | What it proves | What it does not prove |
| --- | --- | --- |
| `Tests/CubeNotchTests/HotkeyCaptureFocusTests.swift` (6 tests) | Default non-key; begin/end key capability + restore; controller start/stop/idempotent restore callbacks; monitor ignores other windows / nil capture; detached keyDown only while overlay is key | A human (or CGEvent) typing into a focused third-party app while Settings is open |
| Isolated seam package `/tmp/CubeHotkeyFocusSeam` | Same 6 tests green without the rest of CubeNotch | Production `ContentView` wiring, Carbon rebind |

Tests use offscreen frames (`-10000,-10000`), no-op activation injectors, and local `NSEvent` construction. They do **not** send global keystrokes into other apps.

## Limitations
- XCTest/`swift test` does not run CubeNotch as a foreground accessory app, so this is not interactive capture proof.
- Local monitors still cannot see keys while another app is active; production therefore activates on **Change…** (explicit user action) and restores the previous frontmost app on stop.
- `requestHotkeyRebind` remains an AppDelegate observer; Settings bind still goes through `GlobalHotKeyManager.setHotkey` directly. Left unchanged (no evidence it is required for focus).
