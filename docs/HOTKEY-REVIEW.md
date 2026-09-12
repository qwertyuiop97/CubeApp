# Global hotkey registration

`GlobalHotKeyManager` stores a shortcut only after Carbon registers it successfully. A failed replacement leaves the previous shortcut working. Zero key codes and modifiers are valid stored values; missing or out-of-range preferences fall back to defaults.

The registrar checks the status returned by `RegisterEventHotKey`, `InstallEventHandler`, and `GetEventParameter`. Events with invalid parameters, a different signature, or a stale ID return `eventNotHandledErr`. Deinitialization removes the hotkey and event handler.

## Tests

```sh
SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" \
swift test -Xswiftc -warnings-as-errors --filter GlobalHotKeyManagerTests
```

The tests exercise persistence, failure recovery, callback replacement, and event filtering. Live Carbon registration tests found that different key combinations can share a signature and ID. Registering an already-taken combination fails with `eventHotKeyExistsErr` instead.

Registration tests do not simulate a physical shortcut press. See [focus tests](HOTKEY-FOCUS-VERIFICATION.md) for the Settings recorder.
