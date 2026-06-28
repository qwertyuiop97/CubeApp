# NEXT — Current Task for Agents

> Read this file first, then read CLAUDE.md, AGENTS.md, and TASKS.md before touching any code.
> Run `make build` after every phase. Fix all errors before moving to the next phase.
> Update this file when a phase is complete: mark it done and set the next phase as current.

---

## CURRENT: Phase 5A — Positions & Spring Animation

**Status: IN PROGRESS**

1. Add `notch` and `bottomCenter` to the `Anchor` enum in `Sources/Core/Services/CubeStateManager.swift`
2. Add positioning math for both in `FloatingOverlayWindow.positionAtAnchor()`:
   - `notch` = top-center, below menu bar, respecting `screen.safeAreaInsets.top`
   - `bottomCenter` = bottom-center with 12pt margin
3. Replace `setFrame(animate: true)` with a spring animation using `NSAnimationContext.runAnimationGroup` — window glides out from the anchor edge on show, not just appears
4. Add double-click gesture on the overlay: double-click anywhere calls `hideWindow()` with the same spring animation (slides back into corner and disappears)
5. Update the anchor picker in the settings tray to show all 6 positions
6. Add monitor picker to settings tray: list `NSScreen.screens` by name, let user pick one, store in `@AppStorage("preferredScreen")`, use it in `positionAtAnchor`

---

## UP NEXT (do not start until Phase 5A is done and building clean)

- **Phase 6A** — Scramble generator (`Sources/Features/Timer/ScrambleGenerator.swift`, WCA-valid 20-move 3x3 scrambles)
- **Phase 6B** — Built-in timer (`SolveTimer.swift`, `TimerView.swift`, spacebar via CGEventTap, Timer tab in UI)
- **Phase 6C** — Time history (`TimeStore.swift`, ao5/ao12/ao100, session management)
- **Phase 6D** — Cross practice mode (scrambles + cross solve tracking in Timer tab)
- **Phase 7A** — Screenshot (CGWindowListCreateImage, save to Desktop + clipboard)
- **Phase 7B** — F2L data (41 cases added to AlgorithmDatabase.swift, F2L tab in browser)

---

## RULES (always apply)
- Never modify or remove existing OLL/PLL cases in AlgorithmDatabase.swift
- Window must remain non-activating at all times except global hotkeys (CGEventTap)
- Spring animations on all show/hide transitions — no linear easing
- All new files go in the correct Sources/ subfolder per AGENTS.md directory layout
