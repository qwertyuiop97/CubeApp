# AGENTS.md

## Current State (2026-06-27)
- Git repo initialized (`git init` done).
- Standard macOS/Swift `.gitignore` present.
- No `Package.swift`, no `.xcodeproj` — pure scaffolding.
- One source file exists: `Sources/Core/Data/AlgorithmDatabase.swift` (finalized, exhaustive).

## Must-Protect Data
- `AlgorithmDatabase.swift` is the single source of truth:
  - All 57 OLL + 21 PLL cases.
  - Every case has `primaryAlgorithm` + ≥2 `alternativeAlgorithms` (never empty or TODO).
- Never duplicate OLL/PLL data elsewhere.
- Never edit structure or cases without explicit verification against the original exhaustive list.
- See `CLAUDE.md` for full protection rules.

## Companion Instruction Files
- `CLAUDE.md`: SwiftUI + AppKit integration, transparent borderless floating `NSWindow`/`NSPanel` rules, dynamic compact/medium/large size modes, notch handling.
- `TASKS.md`: roadmap with algorithm database marked complete; use to track next steps.
- `SCRATCHPAD.md`: window anchoring math and positioning experiments (do not delete ideas here).

## Directory Layout (enforced)
```
Sources/
  App/
  Core/{Models,Data,Services}
  UI/{Components,Views}
  Features/{CubeDisplay,Overlay,Settings}
Resources/{Assets.xcassets,Localizations/}
Tests/
```
Place every new file in the matching subfolder. Do not create top-level source files.

## Commands & Verification
- Always run `git status --short` before and after changes.
- No build system yet. When adding manifest:
  - `swift build` (SPM) or open in Xcode.
- Run `swiftc Sources/Core/Data/AlgorithmDatabase.swift` (or equivalent) to verify the data file compiles in isolation.
- No tests or lint configured yet.

## Floating Window Essentials (read CLAUDE.md first)
- Host is AppKit (`NSPanel` / borderless `NSWindow`).
- Content is SwiftUI via `NSHostingView`/`NSHostingController`.
- Always use modern materials (`.regularMaterial`, `.thinMaterial`).
- Non-activating, floating level, movable by background.
- Support user-scalable compact/medium/large configs persisted via `@AppStorage` or settings model.

## What an Agent Must Never Do
- Touch or fork `AlgorithmDatabase.swift` data.
- Use solid/opaque backgrounds instead of SwiftUI materials.
- Call `NSApplication.shared.activate(ignoringOtherApps:)` except on explicit user action.
- Hard-code algorithm strings in views or other models.
- Commit `.xcuserstate`, `xcuserdata`, `DerivedData`, or build artifacts.

## Quick Ramp-Up Checklist for New Session
1. `git status`
2. Read `CLAUDE.md` (window rules)
3. Read `TASKS.md` (current priorities)
4. Confirm `AlgorithmDatabase.swift` is untouched and complete (57+21 cases)
5. Only then start implementation

Last updated: 2026-06-27
