# NEXT — Current Task for Agents

> Read this file first, then read CLAUDE.md, AGENTS.md, and TASKS.md before touching any code.
> Run `make build` after every phase. Fix all errors before moving to the next phase.
> Update this file when a phase is complete: mark it done and set the next phase as current.
> Log any blockers in PROBLEMS.md immediately. Do not leave them undocumented.

---

## Phase 5A — Positions & Spring Animation
**Status: DONE** (2026-06-27)
- [x] notch + bottomCenter anchors, spring animations, double-click hide, 6-position picker, monitor picker

## Phase 6A — Scramble Generator
**Status: DONE** (2026-06-27)
- [x] ScrambleGenerator.swift, WCA-valid 20-move 3x3 scrambles, no consecutive same face

## Phase 6B — Built-in Timer
**Status: DONE** (2026-06-27)
- [x] SolveTimer.swift, TimerView.swift, global CGEventTap spacebar, Cases↔Timer mode switch

## Phase 6C — Time History
**Status: DONE** (2026-06-27)
- [x] TimeStore.swift, ao5/ao12/ao100, 10 recent solves, New Session

## Phase 6D — Cross Practice Mode
**Status: DONE** (2026-06-27)
- [x] Cross practice toggle, cross scramble generator, session counter

## Phase 7A — Screenshot
**Status: DONE** (2026-06-27)
- [x] ScreenshotService.swift, save PNG to Desktop + clipboard, camera button in header

## Phase 7B — F2L Data
**Status: DONE** (2026-06-27)
- [x] F2LDatabase.swift (41 cases, primary + ≥2 alts), F2L tab in browser, AlgorithmDatabase untouched

---

## CURRENT: Phase 8A — HUD Polish & Missing Requirements

**Status: IN PROGRESS**

These are required items from CLAUDE.md that were never implemented, plus real UX gaps.

### 8A-1: Cleanup
- [ ] **Remove dead code**: Delete `CubeCanvasView` struct from `Sources/UI/MainOverlayViews.swift` (lines ~378–426). It's a placeholder that was never wired up. `CubeStateView.swift` in `Features/CubeDisplay/` is the real visualizer.
- [ ] Verify `make build` still clean after removal.

### 8A-2: Blur Slider (required by CLAUDE.md)
- [ ] Add `@AppStorage("blurIntensity") var blurIntensity: Double = 0.5` (range 0.0–1.0) to ContentView
- [ ] Replace hardcoded `.ultraThinMaterial` background in ContentView with a material that responds to the slider
  - Approach: use `.background(.thinMaterial)` as base and overlay `Color.black.opacity(blurIntensity * 0.45)` on top so the slider adds darkness/opacity
  - The slider controls "how opaque" the background is (0 = very transparent, 1 = fully frosted)
- [ ] Add slider to settings drawer: "Blur" label + `Slider(value: $blurIntensity, in: 0...1)`
- [ ] `make build` clean

### 8A-3: Background Tint (required by CLAUDE.md)
- [ ] Add `@AppStorage("backgroundTint") var backgroundTint: String = "neutral"` 
- [ ] Supported tints: `"neutral"` (no tint), `"dark"` (black overlay), `"light"` (white overlay), `"blue"`, `"purple"`, `"green"` 
- [ ] Apply as a thin `Color.overlay` on top of the material background (opacity ~0.08–0.12 so it's subtle)
- [ ] Add tint picker to settings drawer: small color swatches (use `Circle()` color chips in an `HStack`, tap to select)
- [ ] `make build` clean

### 8A-4: Liquid Glass (research required before touching code)
- [ ] **Research step first**: Search online for "SwiftUI Liquid Glass macOS 26" and "macOS 26 glass material SwiftUI API". Determine:
  - What is the actual SwiftUI API name? (`.glassBackground()`? `.background(.glass)`? something else?)
  - What SDK / Xcode version is required?
  - Are there known build issues or beta instabilities?
- [ ] **Only implement if** a confirmed, compilable API is found. Do NOT guess or use undocumented APIs.
- [ ] If confirmed: wrap the background material in `#available(macOS 26, *)` conditional. The else branch keeps `.ultraThinMaterial` + tint overlay.
- [ ] If NOT confirmed (API unknown or unstable): log in PROBLEMS.md with findings, leave the material as-is, and skip this task — do NOT block the rest of Phase 8A.
- [ ] `make build` clean

### 8A-5: Copy Algorithm Button
- [ ] In `caseDetailView(for:)` in MainOverlayViews.swift: add a clipboard icon button (SF Symbol `"doc.on.doc"`) next to the primary algorithm text
- [ ] On tap: `NSPasteboard.general.clearContents(); NSPasteboard.general.setString(c.primaryAlgorithm, forType: .string)`
- [ ] Brief "Copied" feedback label (same pattern as the existing screenshot "Saved" feedback)
- [ ] `make build` clean

### 8A-6: Search in Case Browser
- [ ] Add `@State private var searchText: String = ""` to ContentView
- [ ] Add a search field above the case list (only visible in Cases mode, not detail or timer)
  - Use `TextField("Search cases…", text: $searchText)` with `.textFieldStyle(.roundedBorder).controlSize(.small)`
- [ ] Filter `filteredCases` by `searchText`: match on `c.name`, `c.caseType`, or `String(c.caseNumber)` (case-insensitive)
- [ ] Clear search when switching F2L/OLL/PLL tabs
- [ ] `make build` clean

### 8A-7: Timer UX Fixes
- [ ] **Best time**: Add `store.bestTime` to TimeStore if not already present; show "Best: X.XX" in timer stats row alongside ao5/ao12/ao100
- [ ] **Single-spacebar flow**: Currently stopped → space → reset → space → start (two presses). Fix: when state is `.stopped`, a single spacebar press should immediately start a new solve (call `reset()` then `start()` in one action inside `toggle()`)
- [ ] **DNF / +2 buttons**: After a solve stops (state == .stopped), show two small buttons: `DNF` and `+2`. 
  - `+2`: adds 2.0 to the last solve time (update both `finalTime` and the stored record)
  - `DNF`: marks the last solve as DNF (store it with time = -1, display as "DNF" in the list)
  - Buttons disappear when a new scramble is requested
  - Update `TimeStore` to support `SolveRecord` having an optional `penalty: Penalty` enum (`.none`, `.plusTwo`, `.dnf`)
- [ ] `make build` clean after all timer changes

---

## Phase 9A — Library Mode Window

**Status: NOT STARTED** (do not begin until Phase 8A is done and building clean)

Library Mode is a full native Mac window (standard chrome, activating, resizable) that coexists with the HUD. HUD never closes when Library opens. Both read from the same AlgorithmDatabase + F2LDatabase — never duplicate data.

### Architecture
- `Sources/App/LibraryWindowController.swift` — `NSWindowController` subclass
  - Opens a standard `NSWindow` (NOT borderless — this one has title bar, traffic lights, resize)
  - `styleMask: [.titled, .closable, .miniaturizable, .resizable]`
  - Min size: 900×600; default: 1100×700
  - Non-singleton is fine; close button dismisses it
  - The window IS activating (unlike the HUD)
- `Sources/Features/Library/LibraryView.swift` — SwiftUI root view for the library
- `Sources/Features/Library/LibraryCaseDetailView.swift` — expanded case detail
- `Sources/Features/Library/LibrarySearchBar.swift` — search component
- AppDelegate: add `"Open Library"` menu item in status bar menu → instantiates and shows `LibraryWindowController`

### Library UI Layout
```
┌─────────────────────────────────────────────────────────────┐
│  [Search...]              CubeNotch Library    [F2L|OLL|PLL] │
├──────────────┬──────────────────────────────────────────────┤
│              │                                              │
│  Case list   │  Case detail (right pane)                   │
│  (sidebar)   │  - Large cube diagram (CubeStateView)       │
│              │  - Primary alg + copy button                │
│  Tap = detail│  - Alternatives list (all of them)          │
│              │  - ★ Favorite toggle                        │
│              │  - "Set as my alg" button (per case)        │
│              │  - Move count for each alg                  │
└──────────────┴──────────────────────────────────────────────┘
```

### Features
- [ ] Full sidebar case list (all 41 F2L + 57 OLL + 21 PLL) with search
- [ ] Larger CubeStateView diagram in detail pane (not the compact HUD version)
- [ ] All alternative algorithms shown (not truncated)
- [ ] Move count per algorithm (count space-separated tokens)
- [ ] **Favorites**: `@AppStorage("favoriteCaseIDs")` — persisted array of favorite case ID strings; star icon in sidebar; "Favorites" filter option
- [ ] **My Algorithm**: user can tap any alternative to set it as "my algorithm" for that case; persisted per case ID in UserDefaults; shown with a checkmark ring in the sidebar
- [ ] Copy button for every algorithm in detail pane
- [ ] Search: real-time filter across name, algorithm text, case number
- [ ] Keyboard navigation: up/down arrows move through case list, Enter opens detail
- [ ] `make build` clean throughout

---

## Phase 9B — Library: Beginner Method Section

**Status: NOT STARTED** (do not begin until Phase 9A is done)

Add a "Learn" tab to the Library for the Layer-by-Layer (LBL) beginner method. This is separate tutorial content — NOT in AlgorithmDatabase.swift.

### New Files
- `Sources/Core/Data/BeginnerMethodDatabase.swift` — standalone struct with the 7 LBL steps
- `Sources/Features/Library/BeginnerStepView.swift` — view for a single step card

### Beginner Method Content (add to BeginnerMethodDatabase.swift)
The standard beginner Layer-by-Layer method — 7 steps:

1. **White Cross** — Form a cross on the white face with all 4 edges aligned to their center colors. No set algorithm; guide the user to think about it. Key tip: front face trick for misaligned edges.
2. **White Corners** — Place all 4 white corners. Trigger: `R U R' U'` (or `L' U' L U`). Repeat until corner drops in.
3. **Middle Layer Edges** — Insert the 4 middle layer edges. Two triggers: Right insert `U R U' R' U' F' U F`, Left insert `U' L' U L U F U' F'`.
4. **Yellow Cross (OLL simplified)** — Get a yellow cross on top (ignoring corner orientation). Trigger: `F R U R' U' F'`. Apply 0–3 times.
5. **Orient Yellow Corners (OLL simplified)** — Orient all yellow corners using the Sune: `R U R' U R U2 R'`. Apply until all corners are oriented.
6. **Permute Yellow Corners (PLL simplified)** — Cycle 3 corners using: `U R U' L' U R' U' L`. Repeat until corners are in the right positions (may need AUF first).
7. **Permute Yellow Edges (PLL simplified)** — Cycle 3 edges using: `F2 U L R' F2 L' R U F2`. One or two applications solves it.

### Library "Learn" Tab
- [ ] Add "Learn" tab to Library's top picker (alongside F2L/OLL/PLL)
- [ ] Shows the 7 steps as cards in a ScrollView
- [ ] Each card: step number, title, description, key algorithm(s) with copy button
- [ ] At the bottom of LBL, add a "Ready for more? Learn CFOP →" button that switches to F2L tab
- [ ] Step 2 (White Corners) links to relevant F2L cases; Steps 4–5 link to OLL; Steps 6–7 link to PLL
- [ ] `make build` clean

---

## RESEARCH PHASE (separate from coding — use Claude Code or Grok DeepSearch, not Kilo Code)

**Goal:** Search the web for resources, libraries, communities, and data sources useful for a speedcubing HUD app. Compile findings and decide what to integrate.

**Search for:**
- Better/more complete OLL, PLL, F2L algorithm databases (e.g. algdb.net, speedsolving.com wiki)
- Fingertrick notation or groupings used by top cubers
- WCA official algorithm sets and any community-preferred alternatives
- Open source speedcubing tools or libraries (timers, scramblers, cube state simulators)
- CSTimer's export format spec (for future time export compatibility)
- Any Swift or macOS libraries relevant to cube visualization or timers
- Popular community sites where users share algorithm sets (CubeSkills, JPerm, etc.)
- Standard scramble generator specs (WCA scramblers are open source)

**Output:** Add a `RESOURCES.md` file to the project listing what was found and whether each is worth integrating, linking to, or referencing for data.

---

## LONG-TERM VISION — Full Speedcubing Library App

The app has two modes that coexist:

**HUD Mode** (current focus): floating borderless overlay, compact, non-activating, for use during active solving sessions on top of a timer.

**Library Mode** (Phases 9A–9B above): a full native Mac window that opens on demand — organized, comprehensive, beautiful. The goal is to be the macOS equivalent of SpeedCubeDB.

### Library Mode should eventually contain:
- **CFOP full coverage:** Cross, F2L (41 cases), OLL (57 cases), PLL (21 cases)
- **Beginner method:** Layer-by-Layer with links into CFOP as user advances
- **Advanced subsets:** ZBLL, COLL, CMLL, OLLCP, Winter Variation, VLS, HLS, WVLS (future)
- **Each case:** primary algorithm, community alternatives, move count, favorites, personal alg selection
- **Search & filter:** by case name, AUF, recognition pattern, subset
- **User customization:** mark favorites, set personal best algorithm per case, track learning progress

### Architecture constraints (always apply):
- HUD mode: existing FloatingOverlayWindow (NSPanel, non-activating, compact) — do NOT modify its window type
- Library mode: standard NSWindow (activating, resizable, full chrome) — separate window controller
- Both read from AlgorithmDatabase + F2LDatabase — never duplicate data
- Library opens/closes independently — HUD stays running

---

## RULES (always apply)
- Never modify or remove existing OLL/PLL cases in AlgorithmDatabase.swift
- Never add algorithm data outside AlgorithmDatabase.swift or F2LDatabase.swift
- Window must remain non-activating at all times except Library Mode (which is a normal window)
- Spring animations on all HUD show/hide transitions — no linear easing
- All new files go in the correct Sources/ subfolder per AGENTS.md directory layout
- Log blockers in PROBLEMS.md immediately — do not silently skip broken features
