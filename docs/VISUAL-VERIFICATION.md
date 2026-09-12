# Visual verification — playback / case detail

Native SwiftUI `ImageRenderer` captures (scale 2) of the owned playback/detail chrome. These are not AppKit `NSPanel` screenshots and do not mutate system Reduce Motion / Reduce Transparency.

## Images

| Capture | Path | Size (px) |
|---|---|---|
| Compact HUD detail, light | [images/playback-compact-light.png](images/playback-compact-light.png) | 480×1076 |
| Compact HUD detail, dark | [images/playback-compact-dark.png](images/playback-compact-dark.png) | 480×1076 |
| Large HUD detail, light | [images/playback-large-light.png](images/playback-large-light.png) | 880×1228 |
| Invalid algorithm (no cube) | [images/playback-error-compact-light.png](images/playback-error-compact-light.png) | 552×166 |

Regenerate:

```bash
CUBEAPP_RENDER_DIR=/tmp/cubeapp-playback-renders \
SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" \
swift test --scratch-path /tmp/cubeapp-polish-build --filter PlaybackRenderingTests
```

Harness: `Tests/CubeNotchTests/PlaybackRenderingTests.swift`. HUD snapshots use `HUDCaseDetailView(scrolls: false)` because `ScrollView` + `ImageRenderer` previously emitted blank frames.

## Design decisions

- **Hierarchy.** Section labels (`PLAYBACK`, `PRIMARY`, `ALTERNATIVES`) at 11pt rounded secondary; live notation is the primary readable string (13pt compact / 15pt medium+ monospaced). Copy chrome stays; the duplicate monospaced dump is omitted when playback already shows live notation (`CaseDetailCopyPolicy`).
- **Transport.** Play / step / reset share one capsule with 28pt hit targets, not 16pt naked icons. Move index sits on the same row; Progress and Speed are separate labeled rows.
- **Progress.** Custom `ProgressTrack` (capsule fill), not `ProgressView`. ImageRenderer drew a full yellow bar plus a red prohibition glyph for `ProgressView(value: 0)` — that is not a real “move 0 of N” state.
- **Materials.** Semantic `.quaternary` fills instead of `Color.white.opacity` (those assumed dark HUD). Glass stays off content. No `NSApplication.activate`.
- **Errors.** Diagram is gated on **successful loaded playback** (`hasLoadedPlayback && visualMode != .textOnly`). Passing `cubeState: nil` is not used: `CubeStateView` would fall back to a valid case-recognition diagram. Invalid token shows “Invalid move “Q”.” plus the source string; transport/progress hidden. Idle load does not flash the animator’s solved reset cube.
- **Motion.** `@Environment(\.accessibilityReduceMotion)` skips the 0.12s index tween. That environment key is **read-only** in the SDK; direct `.environment(\.accessibilityReduceMotion/Transparency, true)` overrides are invalid. Behavior is unit-tested via `PlaybackPresentation`, not by flipping system prefs.
- **No 3D / intra-move animation.** Playback is discrete cube states per token.

## Inspection findings (vision on the PNGs above)

**Compact light/dark (240pt actual window width)**

- Cube diagram present; live T-perm notation readable (wraps to two lines at compact width).
- Transport is a grouped pill; Progress is an empty gray track at move 0 (no prohibition overlay); Speed is a distinct slider at 1×.
- PRIMARY is copy + move count only — algorithm string is not repeated.
- Alternatives and recognition tip remain; copy controls stay.
- Light and dark both use readable semantic chrome (no washed white-on-white).

**Large light**

- Same structure; diagram larger (320×256 metrics). Extra gray padding around the cube remains — `CubeStateView` paints inside a fixed frame centered in a wide card. Not a functionality issue.

**Invalid algorithm**

- Cube suppressed (no solved cube). Banner: **Invalid move “Q”.** with `R U Q` underneath. No transport. Height 166px at 2×, well below a diagram card.
- HUD invalid render (not stored): error banner + PRIMARY copy (“— moves”) + alternatives with copy; still no cube.

## Limitations

- Captures are `ImageRenderer` of SwiftUI, not the floating non-activating `NSPanel` with live materials, blur tint, or window chrome.
- Parent reran `PlaybackRenderingTests` with warnings-as-errors at the actual 240pt compact width: 2 tests passed. Both refreshed compact renders were visually inspected and stored above. No clipping/overlap detected; alternatives wrap densely. Invalid-input capture still uses a 260pt content width plus padding and is not a 240pt layout check.
- Reduce Motion / Reduce Transparency were **not** snapshotted (read-only environment; no system preference mutations).
- `scrolls: false` is snapshot-only; production HUD still scrolls.
- ImageRenderer does not prove hit-testing, play/pause timing, or AppKit first-mouse on a nonactivating panel.
- Concurrent test-target edits from other agents can fail a full `swift test` compile even when this slice’s filters pass.
