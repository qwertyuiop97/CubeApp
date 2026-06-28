# CLAUDE.md — CubeNotch Core Styling & Protection Rules

## SwiftUI + AppKit Integration
- Use AppKit (`NSWindowController`, `NSPanel`, or custom `NSWindow`) as the host for the floating utility.
- Host SwiftUI content via `NSHostingView` or `NSHostingController`.
- AppKit owns window level, styleMask, activation policy, and collection behavior.
- SwiftUI owns all views, materials, layout, and state.

## Floating Window Requirements
- Use transparent, borderless floating `NSWindow` (or `NSPanel` with `.borderless`).
- Typical configuration:
  - `styleMask: [.borderless]`
  - `isOpaque: false`
  - `backgroundColor: .clear`
  - `level: .floating` (or `.statusBar` / `.popUpMenu` for notch proximity)
  - `collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]`
  - `hasShadow: true` (subtle shadow for floating feel)
- Window must be non-activating: do not call `NSApplication.shared.activate(ignoringOtherApps:)` unless user explicitly triggers.
- `isMovableByWindowBackground = true`

## Dynamic User-Scalable Configurations
- Support three size modes: compact, medium, large.
- Size mode must be user-selectable and persist (UserDefaults or similar).
- All UI elements (cards, text, padding, cube diagrams) must scale responsively.
- Use `@AppStorage` or observable settings model for `sizeMode: .compact | .medium | .large`.
- Test layout at all three scales; avoid hard-coded sizes.

## Protect AlgorithmDatabase.swift
- `Sources/Core/Data/AlgorithmDatabase.swift` is the finalized, single source of truth.
- It contains every one of the 57 OLL + 21 PLL cases.
- Every case must always have:
  - `primaryAlgorithm`
  - `alternativeAlgorithms` with at least 2 entries (never empty)
- NEVER:
  - Hard-code OLL/PLL data anywhere else
  - Add/remove cases outside this file
  - Use partial lists or TODO placeholders
- When adding features (search, favorites, learning progress), query from `AlgorithmDatabase`, do not duplicate data.

## Floating Window Panel (CRITICAL)
- The correct AppKit primitive is `NSPanel` with `.nonactivatingPanel` in styleMask and `becomesKeyOnlyIfNeeded = true`.
- NEVER call `NSApplication.shared.activate(ignoringOtherApps: true)` — this is the #1 cause of 1-star reviews on floating utility apps.
- `hidesOnDeactivate = false` so the HUD stays visible when another app takes focus.
- Use `.statusBar` window level (value 25) when anchoring near the notch — not `.floating`.
- Panel position must persist across relaunches in UserDefaults; validate frame against current screen geometry on restore.

## Liquid Glass (macOS Tahoe 26 / macOS 26) — CONFIRMED APIs
- Primary SwiftUI API: `.glassEffect()` — variants: `.regular` (toolbars, HUDs), `.clear` (over images)
- With shape: `.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))`
- With tint: `.glassEffect(.regular.tint(Color.accentColor.opacity(0.5)))` — tint only primary actions
- Multiple adjacent glass elements MUST be wrapped in `GlassEffectContainer(spacing:)` — glass sampling glass produces visual artifacts
- AppKit equivalent: `NSGlassEffectView` with `.cornerRadius`, `.tintColor`, `.style` properties
- **Golden Rule**: glass belongs on controls/toolbar layer only — NEVER on card content, scrollable lists, or backgrounds
- Backward compat pattern (always use this):
  ```swift
  extension View {
      @ViewBuilder func cubeNotchGlass(shape: some Shape = Capsule()) -> some View {
          if #available(macOS 26.0, *) { self.glassEffect(.regular, in: shape) }
          else { self.background(shape.fill(.ultraThinMaterial)).shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6) }
      }
  }
  ```
- Remove any `NSVisualEffectView` from legacy code — it blocks the new glass material
- Reduce Transparency compliance required:
  ```swift
  @Environment(\.accessibilityReduceTransparency) var reduceTransparency
  .glassEffect(reduceTransparency ? .identity : .regular)
  ```

## Typography Scale (enforce in all views)
| Role | Size | Weight | Design | Usage |
|------|------|--------|--------|-------|
| Timer display | 72pt | .light | .default | Main countdown — always `.monospacedDigit()` |
| Ao5/Ao12 stats | 20pt | .regular | .default | Live averages below timer |
| Algorithm moves | 15pt | .medium | .monospaced | R U R' U' notation |
| Case label | 17pt | .semibold | .rounded | "OLL 21" heading |
| Category/group | 13pt | .regular | .rounded | "T Shape", "Dot Case" |
| Footnote/metadata | 11pt | .regular | .default | Move count, ETM |

- Timer must use `.monospacedDigit()` + `.contentTransition(.numericText())` — prevents width jitter
- SF Pro Rounded (`.design: .rounded`) for case labels and group names — warmer, more approachable
- Monospaced (`.design: .monospaced`) for all algorithm notation

## Timer Display Pattern (always use)
```swift
Text(timerString)
    .font(.system(size: 72, weight: .light, design: .default))
    .monospacedDigit()
    .contentTransition(.numericText())
    .animation(.easeInOut(duration: 0.08), value: timerString)
```

## Layout: 8pt Grid
- All padding/spacing must be multiples of 8pt (4pt for tight internal spacing)
- `.padding(8)` tight, `.padding(16)` default, `.padding(24)` outer insets
- Corner radii: 12pt for cards, 8pt for buttons, `Capsule()` for pill buttons — always `style: .continuous`
- Use `.containerConcentric` for nested shapes that should match parent radius

## Color / Tint System
- Single accent color — defer to `Color.accentColor` (respects user system preference)
- Timer state colors only: `.green` (armed/ready), `.orange` (inspection < 5s)
- Semantic system colors only — no hard-coded hex values
- Background tint modes (4): `.neutral` (clear), `.dark` (black 0.3 opacity), `.light` (white 0.15 opacity), `.accent` (accentColor 0.2 opacity)
- Blur intensity slider maps to tint opacity: `blurTintOpacity = (1.0 - blurIntensity) * 0.4`

## Aesthetic Direction
- Target: premium, modern, slick — not just "dark mode with blur"
- Glass on controls/toolbar, never on content — this is the single most important rule
- Add a blur intensity slider in settings (user controls how transparent/blurry the overlay background is)
- Add background tint options (neutral/dark/light/accent) in settings
- Use SF Symbols throughout — no custom icons unless necessary
- Every visual decision should feel like it belongs natively on macOS
- No custom scrollbars, no hover states that don't match macOS norms, no flickering on view transitions
- Animations play once on user-triggered show — NOT on every workspace switch or Mission Control return
- Solid dark backgrounds = uninstall within 2 weeks. Materials and glass = kept for months.

## Accessibility Requirements
- `@Environment(\.accessibilityReduceMotion)` — disable/simplify all animations when true
- `@Environment(\.accessibilityReduceTransparency)` — use `.identity` glass and solid fallback materials
- Use semantic font sizes (`.body`, `.headline`) except timer display (fixed 72pt is intentional)
- Test with Reduce Transparency ON before every release

## Other Critical Reminders
- Keep the window lightweight — no heavy computation on main thread.
- Do not play entry animations on every workspace switch — only on explicit user-triggered show.
- `isMovableByWindowBackground = true` — HUD must be draggable by clicking anywhere on it.
