# CubeNotch Roadmap & Progress

## Completed
- [x] AlgorithmDatabase.swift finalized (57 OLL + 21 PLL cases, each with primary + ≥2 alternatives)
- [x] Project directory structure scaffolded (Sources/, Resources/, Tests/)
- [x] Git initialized + .gitignore created
- [x] AGENTS.md, CLAUDE.md, TASKS.md, SCRATCHPAD.md created
- [x] Core layer files scaffolded (AppDelegate, FloatingOverlayWindow, CubeStateManager, MainOverlayViews)

## Phase 1 — Foundation (Window on Screen)
- [x] Verify `make build` / `swift build` compiles cleanly with no errors
- [x] FloatingOverlayWindow: NSPanel appears on screen, borderless, transparent, floating level, non-activating
- [x] Corner anchoring: one-click snap to Top-Left, Top-Right, Bottom-Left, Bottom-Right (notch-safe math)
- [x] Size modes: Compact / Medium / Large with @AppStorage persistence, window resizes on change

## Phase 2 — Core Content UI
- [ ] OLL/PLL case browser: segmented/tab picker, scrollable case list
- [ ] Case detail view: primary algorithm text + alternatives, WCA notation display
- [ ] Settings tray: slide-out panel for size mode, corner snap, visualizer mode toggle

## Phase 3 — Canvas Visualizer (CubeStateView.swift)
- [ ] CubeStateView.swift: SwiftUI Canvas 2D sticker diagram (Sources/Features/CubeDisplay/)
- [ ] Draw 2D top-down last layer with correct OLL/PLL sticker colors
- [ ] Mode 1 — Pre-Execution: sticker layout user must recognize before executing
- [ ] Mode 2 — Setup State: invert algorithm sequence, show scramble text + inverted sticker state
- [ ] Mode 3 — Text-Only: collapse Canvas entirely, show algorithm string only with clean transition
- [ ] Canvas scales with Compact / Medium / Large size modes

## Phase 4 — Polish & Extras
- [ ] Global hotkey / menu bar icon for quick show/hide toggle
- [ ] Multiple monitor + notch-safe positioning (follow active screen or stay on primary)
- [ ] Unit tests for AlgorithmDatabase integrity (57 OLL + 21 PLL, no empty alternatives)
- [ ] Launch-at-login support (LSUIElement / accessory activation policy)
- [ ] Accessibility (VoiceOver, keyboard nav)

## Future / Stretch
- [ ] Persistence for favorites / learning progress
- [ ] iCloud sync
- [ ] Community algorithm contributions
- [ ] Auto-hide when full-screen apps are active

---

## Feature Reference
Full user-authored feature checklist is in `SCRATCHPAD.md` under "Canonical Feature Checklist".

## Guiding Principles
- Four-layer architecture: Window Engine → State Manager → Canvas Visualizer → UI Assembly
- AppKit owns the window. SwiftUI Canvas owns all visuals.
- Data exclusively from protected `AlgorithmDatabase.swift` — never duplicate.
- Non-activating at all times. Spacebar must always reach background timer.

Last updated: 2026-06-27
