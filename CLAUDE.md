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

## Aesthetic Direction
- Target: premium, modern, slick — not just "dark mode with blur"
- User is on macOS 27 beta. Use Liquid Glass materials if available via SwiftUI APIs; fall back to `.ultraThinMaterial` for older versions
- Add a blur intensity slider in settings (user controls how transparent/blurry the overlay background is)
- Add background tint options (neutral/dark/light/accent) in settings
- Use SF Symbols throughout — no custom icons unless necessary
- Every visual decision should feel like it belongs natively on macOS

## Other Critical Reminders
- Prefer modern SwiftUI materials: `.regularMaterial`, `.thinMaterial`, `.ultraThinMaterial` — upgrade to Liquid Glass when available.
- Keep the window lightweight — no heavy computation on main thread.
- Respect reduced motion and accessibility.
