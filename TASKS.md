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
- [x] OLL/PLL case browser: segmented picker (OLL / PLL tabs), scrollable case list
- [x] Case detail view: primary algorithm text + all alternatives, WCA notation display
- [x] Settings tray: custom slide-out panel (right edge) for size, anchor, visual mode

## Phase 3 — Canvas Visualizer (CubeStateView.swift)
- [x] CubeStateView.swift: SwiftUI Canvas 2D sticker diagram (Sources/Features/CubeDisplay/)
- [x] Draw 2D top-down last layer with correct OLL/PLL sticker colors (U + side hints)
- [x] Mode 1 — Pre-Execution: sticker layout user must recognize before executing
- [x] Mode 2 — Setup State: invert algorithm sequence, show inverted sticker state
- [x] Mode 3 — Text-Only: collapse Canvas entirely (hidden when .textOnly)
- [x] Canvas scales with Compact / Medium / Large size modes

## Phase 4 — Polish & System
- [x] Global hotkey (Option+Space) + menu bar icon for quick show/hide toggle
- [x] Multiple monitor + notch-safe positioning (follow active screen toggle + per-screen anchoring)
- [x] Unit tests for AlgorithmDatabase integrity (57 OLL + 21 PLL, no empty alternatives)
- [x] Launch-at-login support (SMAppService + toggle in settings)
- [x] Accessibility (VoiceOver labels, keyboard nav on core controls)

## Phase 5 — Animation & Positioning
- [x] Spring slide-in/slide-out: window glides out from anchor corner on show, retracts on double-click (NSAnimationContext spring, not linear)
- [x] Expand snap positions to 6: Top-Left, Top-Right, Bottom-Left, Bottom-Right, Notch (top-center, notch-safe), Bottom-Center
- [x] Monitor selector: let user pick which connected display the overlay lives on (NSScreen list in settings)
- [x] Focus-safe overlay: always non-activating — clicking overlay or settings tray never steals keyboard focus

## Phase 6 — Built-in Timer & Training
- [ ] Scramble generator: WCA-valid 3x3 random-move scrambles (displayed before each solve)
- [ ] Built-in solve timer: start/stop via global spacebar hotkey (registered globally so browser/other apps don't intercept it)
  - DESIGN NOTE: window is non-activating, so spacebar must be captured via CGEventTap or global hotkey — not standard key press. Implement carefully to avoid breaking spacebar in other contexts when timer is not active.
- [ ] Time history: store solve times locally (ao5, ao12, ao100, session view)
- [ ] Session management: start new session, view past sessions
- [ ] Cross practice mode: generate scrambles and prompt user to solve only the white cross; track cross solve count per session
- [ ] Screenshot feature: capture the current overlay state as an image, save to Desktop or clipboard (NSImage / CGWindowListCreateImage)

## Phase 7 — Algorithm Data Expansion
- [ ] Add all 41 F2L cases to AlgorithmDatabase.swift (primary + ≥2 alternatives each, same rules as OLL/PLL)
- [ ] F2L tab added to case browser (alongside OLL / PLL)

## Stretch / Future
- [ ] Export times in CSTimer-compatible JSON format for manual import
- [ ] Favorites + learning progress persistence
- [ ] iCloud sync
- [ ] Auto-hide when full-screen apps are active
- [ ] Community algorithm contributions

---

## Guiding Principles
- Four-layer architecture: Window Engine → State Manager → Canvas Visualizer → UI Assembly
- AppKit owns the window. SwiftUI Canvas owns all visuals.
- Data exclusively from protected `AlgorithmDatabase.swift` — never duplicate.
- Window is non-activating at all times EXCEPT global hotkeys (spacebar timer, Option+Space toggle) which are registered via CGEventTap.
- Spring animations on all show/hide transitions — no linear easing.

Last updated: 2026-06-27
