# Phase 2 Plan: OLL/PLL Case Browser, Detail View, Settings Tray

**Plan ID**: 1782604207-phase-2-oll-pll-browser  
**Date**: 2026-06-27  
**Status**: Ready for implementation (no source edits in this planning session)

## Goal
Replace the current single-case header+canvas+algs UI with a full OLL/PLL case browser inside the existing floating NSPanel. Users browse cases via segmented tabs and list, drill into detail, and commit a case as the live current case. Replace the popover settings with a custom slide-out tray. Keep the window lightweight, non-activating, material-based, and fully responsive to Compact/Medium/Large.

## Scope (Strict)
- OLL (57) + PLL (21) only. Total 78 cases from the protected `AlgorithmDatabase`.
- **No changes whatsoever** to `Sources/Core/Data/AlgorithmDatabase.swift` (per AGENTS.md + CLAUDE.md).
- No F2L data or F2L tab (TASKS.md F2L item deferred; see "F2L Note" below).
- Browser fully replaces the previous main content flow (no persistent "current header" above the browser).
- Use only existing `CubeCanvasView` (reuse + pass correct visualMode/size).

## Key Decisions (Resolved During Planning)
- Navigation: Simple `@State` view swap (list vs detail) inside `ContentView` or new view — no `NavigationStack`.
- Integration: Browser **is** the UI. List → tap row → detail. Detail has "Use this case".
- List rows: Minimal `# . Name` only. Optional checkmark if matches `manager.currentCase.id`.
- Detail: Full `CubeCanvasView` (respects `visualMode` and `sizeMode`), full primary (monospace), **all** alternatives, "Use this case" button.
- Commit flow: New `CubeStateManager.selectCase(_:)` that syncs `currentIndex` + sets `currentCase` + posts `.cubeStateDidChange`.
- Tabs: Segmented `OLL | PLL` only (no F2L placeholder).
- Settings: Custom right-edge slide-out drawer (ZStack + `.offset` + `.animation`, `.regularMaterial` background). Gear icon always present in list and detail headers.
- Header per mode:
  - List: Segmented tabs + "Browse" title + Random + Gear.
  - Detail: Back chevron + case name/type + "Use this" + Gear.
- Controls: Remove prev/next arrows for Phase 2 (replaced by browser selection + random).
- Data access: Direct static (`AlgorithmDatabase.ollCases`, `.pllCases`). No new service layer.
- Random: Global (across OLL+PLL) or tab-scoped — keep simple global for Phase 2.
- After "Use this": call `selectCase`, notify, animate back to list (row now shows indicator).

## F2L Note
TASKS.md Phase 2 lists "Add all 41 F2L cases to AlgorithmDatabase.swift". This is **out of scope** and forbidden by AGENTS.md/CLAUDE.md ("Never edit", "Must-Protect Data", "What an Agent Must Never Do"). Browser implemented for existing 78 cases only. F2L addition requires a **separate** data file later (e.g. `F2LDatabase.swift`) + plan update.

## Constraints (Must Follow)
- AGENTS.md: Directory layout, `git status --short` before/after, `make build` after every edit, protect `AlgorithmDatabase.swift`.
- CLAUDE.md: NSPanel + SwiftUI, `.regularMaterial`/`.thinMaterial`, `@AppStorage` for size/anchor, non-activating (no `activate(ignoringOtherApps)`), no hard-coded alg strings.
- Existing: `CubeStateManager` + `FloatingOverlayWindow` + `@AppStorage` sync + `NSHostingController`.
- Window sizes remain authoritative via `SizeMode.windowSize`.
- All changes must keep the panel non-activating and movable by background.

## Ordered Task List

1. **Preparation**
   - Run `git status --short`.
   - Read AGENTS.md, CLAUDE.md, TASKS.md, current sources (no edits yet).
   - Confirm `AlgorithmDatabase.swift` untouched (78 cases, each with primary + ≥2 alts).

2. **Extend CubeStateManager** (`Sources/Core/Services/CubeStateManager.swift`)
   - Add:
     ```swift
     public func selectCase(_ c: CubeCase) {
         if let idx = allCases.firstIndex(where: { $0.id == c.id }) {
             currentIndex = idx
         }
         currentCase = c
         NotificationCenter.default.post(name: .cubeStateDidChange, object: nil)
     }
     ```
   - Keep `allCases`, `currentIndex`, existing `next/prev/random` unchanged.
   - Verify index sync works for cycling after browser use.

3. **Refactor / Replace Main UI** (`Sources/UI/MainOverlayViews.swift`)
   - Introduce `@State` for browser: `enum BrowserMode { case list, detail(CubeCase) }` or `isShowingList: Bool + selectedCase: CubeCase?`.
   - Extract or inline:
     - `CaseListView` (segmented OLL/PLL + `ScrollView` + `ForEach` rows).
     - `CaseDetailView` (re-uses `CubeCanvasView`, primary alg, all alts, "Use this case").
   - List rows: `HStack { Text("\(c.caseNumber). \(c.name)") ; if isCurrent { Image(systemName: "checkmark") } }`.
   - Filtering: `@State var selectedType: String = "OLL"`. Compute filtered list from static access.
   - Detail "Use this case": `manager.selectCase(case); /* animate back */`.
   - Random button: calls `manager.randomCase()` (works globally).
   - Remove or deprecate old header/mainContent/algorithmSection/prev/next for browser flow.
   - Keep settings gear + new drawer logic.
   - Preserve `@AppStorage` bindings + environment manager + notification receiver.

4. **Implement Custom Settings Drawer (Tray)**
   - In `ContentView` (or root browser view): `ZStack` containing main browser content + settings drawer.
   - Drawer: right-edge, slides in with `.offset(x: showSettings ? 0 : 280)`, `.animation(.easeInOut, value: showSettings)`.
   - Background: `.regularMaterial` + subtle border.
   - Content: existing three `Picker`s (Size via `sizeBinding`, VisualMode, Anchor via `anchorBinding`).
   - Toggle via gear button (always visible). Close on tap outside or dedicated close.
   - Drawer width: ~240–280pt (scales lightly with sizeMode if desired; keep simple).
   - Ensure drawer does not break non-activating or material rules.

5. **Header Layout per Mode**
   - List header: `HStack { Picker/segmented(OLL|PLL); Spacer(); Text("Browse"); Spacer(); Random button; Gear }`.
   - Detail header: `HStack { Back button; VStack(name + type#); Spacer(); "Use this case" button; Gear }`.
   - "Use this case" styled as prominent (`.buttonStyle(.borderedProminent)` or plain with bold).
   - All elements respect current `sizeMode` (fonts/padding via dynamic or computed).

6. **Reuse & Adapt Existing Components**
   - `CubeCanvasView` stays in `MainOverlayViews.swift` (or move to `Sources/UI/Components/CubeCanvasView.swift`).
   - Pass `visualMode: manager.visualMode` and let it scale via outer frame.
   - In detail: show canvas unless `visualMode == .textOnly`.
   - Algorithm text always shown in detail (even in setup mode? follow existing logic or always for detail).

7. **File Placement & New Files (per AGENTS layout)**
   - Prefer adding inside `MainOverlayViews.swift` first (keeps change surface small).
   - If splitting: new files only in:
     - `Sources/UI/Components/` (e.g. `CaseListRow.swift`, `CaseDetailView.swift`)
     - `Sources/UI/Views/` (e.g. `CaseBrowserView.swift`)
   - Do **not** create top-level source files.
   - Update any `CubeStateManagerKey` / environment if needed (already present).

8. **Persistence & State Sync**
   - Existing `@AppStorage` + bindings for size/anchor remain.
   - Browser selection does **not** persist selected case (only via manager `currentCase` + notification).
   - On launch, initial case is still the first (or last persisted via other means); browser starts in list view.

9. **Verification Sequence (Mandatory After Every Edit)**
   - `git status --short`
   - `make build` (must succeed with "Build complete!" and zero errors)
   - Repeat for each logical change.
   - Run the app: `swift run` or `make run`.
   - Test at all three sizes (Compact/Medium/Large) via settings drawer.
   - Test: switch tabs, scroll, tap row → detail, back, "Use this case" (check header updates + canvas + alts), random, cycling still works after selection.
   - Test drawer open/close, pickers update live (size resizes window, anchor moves, visualMode affects canvas).
   - Verify non-activating: click around, spacebar should still work in background timer app.
   - Check materials, no hard-coded alg strings outside database.

10. **Documentation Updates**
    - Update `TASKS.md`: mark Phase 2 items done (except F2L). Add note about F2L scope.
    - Optionally add brief entry to `SCRATCHPAD.md` if new anchoring/UI math appears.
    - Do not modify AGENTS.md, CLAUDE.md, or `AlgorithmDatabase.swift`.

11. **Final Checks**
    - `git status --short` (only expected changed files).
    - Full `make build`.
    - Confirm 78 cases browsable, all alternatives visible in detail, index sync correct.

## Risks & Edge Cases
- Index desync after `selectCase`: mitigated by new method that searches `allCases`.
- Very small compact size (240x300): list rows must stay compact (single-line, no heavy padding). Detail must still fit canvas + alts.
- Scroll performance: 78 items is trivial; no virtualization needed.
- VisualMode in detail: canvas respects it (textOnly hides canvas).
- Current case indicator: must update live when random or external change occurs (use `onReceive` or `@Observable` observation).
- Drawer on tiny window: ensure it doesn't push content off-screen; use overlay or clip if needed.
- "Use this" from detail of a case that is already current: still works (no-op or just back).
- Tab change while in detail: decide policy (auto-back to list, or keep detail? Recommend auto-back on tab switch for simplicity).

## Validation Steps (Implementation Agent Must Execute)
- Every file edit followed by `git status --short` + `make build`.
- Manual run at Compact + Medium + Large.
- Exercise full flow: OLL list → detail → Use → verify current + cycling.
- PLL list → same.
- Random from list.
- All three settings in drawer affect live state.
- No build warnings/errors.
- Confirm `AlgorithmDatabase.swift` git diff is empty.

## Files Expected to Change
- `Sources/Core/Services/CubeStateManager.swift` (add `selectCase`)
- `Sources/UI/MainOverlayViews.swift` (major refactor for browser + drawer)
- `TASKS.md` (progress + F2L scope note)
- Possibly new files under `Sources/UI/Components/` or `Sources/UI/Views/` (optional; can be done in one file first)

## Open Questions
None — all critical decisions resolved in planning.

## References
- AGENTS.md (must-protect data, layout, commands)
- CLAUDE.md (window rules, materials, @AppStorage)
- TASKS.md (Phase 2 items + F2L note)
- SCRATCHPAD.md (architectural blueprint, current UI description)
- Current sources: `CubeStateManager.swift:29`, `MainOverlayViews.swift:4`, `AppDelegate.swift:26`, `AlgorithmDatabase.swift:22` (read-only)

**Ready for implementation agent.** After saving, switch to a coding-capable agent and begin with `git status` + read plan.
