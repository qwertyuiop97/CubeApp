# Shortcut recording and focus

The overlay normally cannot become the key window. Clicking **Change…** in Settings temporarily permits keyboard focus and activates CubeNotch so a local event monitor can receive the new shortcut.

Cancel, Escape, closing Settings, leaving the view, or saving a shortcut ends recording. The controller removes its monitor, restores the panel's usual behavior, and returns activation to the previous app. It ignores events belonging to other CubeNotch windows.

## Test coverage

`HotkeyCaptureFocusTests` checks the default window behavior, temporary focus, cleanup, repeated cancellation, and event filtering. Tests construct local `NSEvent` objects and use offscreen panels with injected activation callbacks. They do not send global keystrokes.

The AppKit probe showed that `makeKey()` does not make the original panel key. Temporarily permitting `canBecomeKey` allows an ordered-front panel to become key in the test environment.

A foreground test with another app active is still needed to confirm the complete recording interaction. Offscreen tests do not establish that result.
