# AGENTS.md

## Current State
- Native macOS SwiftPM executable (`Package.swift`), SwiftUI views hosted by AppKit.
- `NEXT.md` is the current work/status entry point; dated phase details below it are historical.
- The repository includes HUD, Library, timer, trainer, stats, onboarding and XCTest suites.
- Protected content: 57 OLL + 21 PLL in `AlgorithmDatabase.swift`, 41 F2L in `F2LDatabase.swift`.
- Do not infer correctness from old checkboxes: run the build/tests and read current issues.

## Must-Protect Data
- `AlgorithmDatabase.swift` is the single source of truth:
  - All 57 OLL + 21 PLL cases.
  - Every case has `primaryAlgorithm` + ≥2 `alternativeAlgorithms` (never empty or TODO).
- Never duplicate OLL/PLL data elsewhere.
- Never edit structure or cases without explicit verification against the original exhaustive list.
- See `CLAUDE.md` for full protection rules.

## Companion Instruction Files
- `CLAUDE.md`: SwiftUI + AppKit integration, transparent borderless floating `NSWindow`/`NSPanel` rules, dynamic compact/medium/large size modes, notch handling.
- `NEXT.md`: current task for agents — always read this first, then update it when a phase completes.
- `TASKS.md`: roadmap with algorithm database marked complete; use to track next steps.
- `PROBLEMS.md`: live issue tracker — log blockers and build errors here as you hit them; update status accurately.
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
- `make build` and `make test` are the supported verification commands (warnings are errors).
- The Makefile pairs SDKROOT with the selected Xcode SDK. This avoids an inherited CommandLineTools SDK being incompatible with Xcode's compiler.
- For direct Swift commands: `SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" swift test`.
- For concurrent development, use separate scratch paths or isolated packages to avoid mixing unfinished test targets; run the full repository suite again after integration.
- Never commit build products or local rendering/test artifacts.

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
2. Read `NEXT.md` (current task — start here)
3. Read `CLAUDE.md` (window rules)
4. Read `PROBLEMS.md` (check for any open blockers before starting)
5. Confirm `AlgorithmDatabase.swift` is untouched and complete (57+21 cases)
6. Only then start implementation

## Problems Tracker Protocol
- Open `PROBLEMS.md` at the start of every session. If any items are `in-progress` from a previous session, reset them to `pending` (they weren't resolved).
- When you hit a blocker: add an entry to `PROBLEMS.md` immediately, status `pending`.
- When you start fixing it: update status to `in-progress`.
- When it's fixed: check the box and move the entry to "Solved Problems".
- If you finish your session with an unsolved problem: make sure status is back to `pending`, not `in-progress`.
- Claude Code reviews this file and can provide plans for hard problems — keep notes detailed.

Last updated: 2026-06-27
