# Hotkey Carbon registrar review remediation

## Scope
`Sources/Core/Services/GlobalHotKeyManager.swift` and `Tests/CubeNotchTests/GlobalHotKeyManagerTests.swift` only.

## Findings and fixes

| Review finding | Result |
|---|---|
| `InstallEventHandler` OSStatus ignored; register succeeded without a handler | Fixed. Install failure rolls back the new hotkey, returns `false`, and does not persist via `setHotkey`. |
| `GetEventParameter` OSStatus ignored; `id == 1` only; `noErr` for unrelated events | Fixed. Malformed parameter, wrong signature, or non-active id returns `eventNotHandledErr`. Nil `userData` does too. |
| Missing `deinit` unregister with `passUnretained` callback | Fixed. `deinit` calls `unregister()` (hotkey + handler). |
| Register new before removing old with same signature/`id=1` (possible duplicate ID failure) | **Not reproduced.** Live Carbon: same signature+id, different combos → both `noErr`. Same combo, different ids → `eventHotKeyExistsErr` (`-9878`). Registrar still uses signature + incrementing active id, registers new before dropping old, and keeps the old binding if the new combo fails. |

## Verification
Command:

```
SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" swift test -Xswiftc -warnings-as-errors --filter GlobalHotKeyManagerTests
```

- **25 tests, 0 failures** (16 existing manager/persistence tests + 9 registrar/Carbon tests).
- Injected `CarbonHotKeyAPI` seam covers handler-install failure, replacement failure, unique ids, event filtering, and deinit.
- Live Carbon tests ran in this environment (not skipped): duplicate ID allowed; duplicate combo rejected; live registrar keeps the old combo when the new combo is already taken.

## ID collision
**Not reproduced as a registration failure.** Duplicate `(signature, id)` is legal for distinct key combos. The real Carbon conflict is a duplicate **combo**, independent of id.
