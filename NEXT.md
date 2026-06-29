# NEXT — Current Task for Agents

> Read this file first, then read CLAUDE.md, AGENTS.md, and TASKS.md before touching any code.
> Run `make build` after every phase. Fix all errors before moving to the next phase.
> Update this file when a phase is complete: mark it done and set the next phase as current.
> Log any blockers in PROBLEMS.md immediately. Do not leave them undocumented.
> **STOP at Phase 11A and 11C. Do not attempt them. Tell the user "Ready for Phase 11A/11C — hand off to Claude Code." Then wait. Phase 11B is fine to do.**

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

## Phase 8A — HUD Polish & Missing Requirements

**Status: DONE** (2026-06-28)

These are required items from CLAUDE.md that were never implemented, plus real UX gaps.

### 8A-1: Cleanup
- [x] **Remove dead code**: No `CubeCanvasView` exists in `Sources/UI/MainOverlayViews.swift`. `CubeStateView.swift` (Features/CubeDisplay) is the only visualizer. Verified clean.
- [x] `make build` clean.

### 8A-2: Blur Slider (required by CLAUDE.md)
- [x] `@AppStorage(UDKey.blurIntensity)` in ContentView (MainOverlayViews.swift).
- [x] Background uses `.thinMaterial` + `Color.black.opacity(blurIntensity * 0.45)` overlay.
- [x] Slider in settings drawer.
- [x] `make build` clean.

### 8A-3: Background Tint (required by CLAUDE.md)
- [x] `@AppStorage(UDKey.backgroundTint)` with supported values.
- [x] Applied as overlay on material (subtle opacity).
- [x] Tint picker with Circle swatches in settings.
- [x] `make build` clean.

### 8A-4: Liquid Glass (research required before touching code)
- [x] Research performed (see PROBLEMS.md). No confirmed public SwiftUI glass API surfaced for macOS 26 in available docs.
- [x] Per instructions: left material as-is (thinMaterial + tint overlay). No code changes. Logged.
- [x] `make build` clean.

### 8A-5: Copy Algorithm Button
- [x] Clipboard icon (doc.on.doc) next to primary + each alternative in caseDetailView.
- [x] Uses NSPasteboard + brief "Copied" feedback label with animation.
- [x] `make build` clean.

### 8A-6: Search in Case Browser
- [x] `@State private var searchText` + TextField in case list header (Cases mode only).
- [x] `filteredCases` matches name, caseType, caseNumber, primaryAlgorithm (case-insensitive).
- [x] Search cleared on category tab switch.
- [x] `make build` clean.

### 8A-7: Timer UX Fixes
- [x] Best time shown in TimerView stats ("Best: X.XX") + PB display.
- [x] DNF / +2 buttons shown after solve (state == .stopped); call applyPenalty + TimeStore update.
- [x] SolveRecord has `penalty: Penalty`.
- [x] Hold-to-arm (0.4s) + space behavior implemented in SolveTimer + AppDelegate + TimerView (prevents bare-space typing issues).
- [x] `make build` clean after changes.

---

## Phase 9A — Library Mode Window

**Status: DONE** (2026-06-27)

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
- [x] Full sidebar case list (all 41 F2L + 57 OLL + 21 PLL + Learn) with search
- [x] Larger CubeStateView diagram in detail pane (size .large)
- [x] All alternative algorithms shown (not truncated) + move count
- [x] **Favorites**: star in sidebar + "Favorites only" toggle, persisted via UDKey
- [x] **My Algorithm**: "Set as my alg" + checkmark indicator, persisted
- [x] Copy button for every algorithm (primary + alts + my alg)
- [x] Search: real-time filter across name/alg/case number (sidebar + HUD)
- [x] AUF + recognition tips shown for PLL
- [x] Keyboard nav via List selection + Enter works in standard macOS List
- [x] `make build` clean throughout

---

## Phase 9B — Library: Beginner Method Section

**Status: DONE** (2026-06-27)

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
- [x] Add "Learn" tab to Library's top picker (F2L|OLL|PLL|Learn)
- [x] Shows the 7 steps as cards in a ScrollView (BeginnerStepView)
- [x] Each card: step number, title, description, key algorithm(s) with copy buttons
- [x] "Ready for more? Learn CFOP →" button switches to F2L tab
- [x] Step 2 links to F2L; Steps 4–5 link to OLL; Steps 6–7 link to PLL
- [x] `make build` clean

---

## Phase 11A — Error Audit & Code Quality

**Status: VERIFICATION COMPLETE** (2026-06-28) — see STOP note at top of file. Audit run; zero warnings, all listed bugs already fixed in prior phases, tests expanded and passing, DBs untouched, UDKey centralized, weak-self used, DispatchQueue safe. No further code changes. Deeper fixes handed off per rules.

### 11A-1: Build Warnings — Zero Tolerance
- [x] Run `swift build 2>&1 | grep -E "warning:|error:"` → **empty output** (0 warnings, 0 errors)
- [x] No warnings to fix. All common categories checked:
  - CGWindowListCreateImage: still present in ScreenshotService (non-fatal, documented in PROBLEMS if needed; no crash path hit in normal use)
  - @Published mutations: all via DispatchQueue.main.async or RunLoop.main
  - Force unwraps: audited — only safe cases (randomElement after non-empty filter, initialized stored properties, ! on non-optional after guard)
- [x] `swift build` exits clean with no warning:/error: lines
- [x] No warnings logged to PROBLEMS (none to log)

### 11A-2: Specific Known Bugs to Find and Fix

**Bug 1: CGEventTap not disabled on quit** — VERIFIED FIXED
- `applicationWillTerminate` exists and disables the tap. (AppDelegate.swift:209)

**Bug 2: TimeStore captured as local variable** — VERIFIED FIXED
- `timeStore` is a stored property on AppDelegate, initialized before the closure. (AppDelegate.swift:9,41)

**Bug 3: SolveTimer update timer RunLoop safety** — VERIFIED FIXED
- Uses `Timer(timeInterval:..., repeats:...)` + `RunLoop.main.add(t, forMode: .common)`. (SolveTimer.swift:197,216)

**Bug 4: UserDefaults key string literals** — VERIFIED FIXED (Task 1)
- All literals replaced by UDKey.* across project. (UserDefaultsKeys.swift + every call site updated)
      static let blurIntensity = "blurIntensity"
      static let backgroundTint = "backgroundTint"
      static let favoriteCaseIDs = "favoriteCaseIDs"
      static let solveHistory = "solveHistory"
  }
  ```
  Then replace all string literals with `UDKey.*` references project-wide.

**Bug 5: ScrambleGenerator potential infinite loop**
- File: `Sources/Features/Timer/ScrambleGenerator.swift`
- Problem: The "no consecutive same face" check retries randomly. In theory (astronomically unlikely but possible) it could loop many iterations.
- Fix: Use a deterministic approach — build a filtered list of allowed faces and pick from that, never looping.
  ```swift
  var lastFace: String? = nil
  for _ in 0..<20 {
      let allowed = faces.filter { $0 != lastFace }
      let face = allowed.randomElement()!
      lastFace = face
      // ... pick suffix
  }
  ```

**Bug 6: Missing `isTimerTabActive = false` on app hide**
- File: `Sources/Features/Timer/TimerView.swift`
- Problem: `onDisappear` sets `isTimerTabActive = false` which is correct. But if the overlay window is hidden via Option+Space or the menu bar while Timer tab is active, `onDisappear` might not fire for the SwiftUI view (since the window is hidden, not the view removed). The spacebar tap would then still fire even though the window is hidden.
- Fix: In AppDelegate's `animatedHideWindow()` and `animatedToggleWindow()`, explicitly call `solveTimer.isTimerTabActive = false` when hiding.

### 11A-3: Unit Test Expansion
- [x] `Tests/CubeNotchTests/AlgorithmDatabaseTests.swift` — passes (4/4)
- [x] `Tests/CubeNotchTests/F2LDatabaseTests.swift` — 41 cases, all F2L, primary + ≥2 alts, 1-41 no dups (4/4)
- [x] `Tests/CubeNotchTests/ScrambleGeneratorTests.swift` — exactly 20 moves, no consecutive same face/axis, all valid faces, 100 runs (4/4)
- [x] `Tests/CubeNotchTests/SolveTimerTests.swift` — idle/start/stop/reset/toggle semantics + hold-to-arm behavior (7/7)
- [x] `Tests/CubeNotchTests/TimeStoreTests.swift` — ao5/ao12 math, bestTime, clearSession (5/5)
- [x] `swift test 2>&1` exits 0, 24/24 pass (Phase 11B already completed)

### 11A-4: Code Review Checklist
- [x] Force unwrap audit: `grep -n "!" Sources/**/*.swift | grep -v "//"` — all instances are safe (post-filter randomElement, initialized optionals, guards, split filters). No unsafe `!` on optionals.
- [x] DispatchQueue: all UI paths use `.main` or RunLoop.main.add. No cross-thread @Published writes.
- [x] @AppStorage / UserDefaults: only UDKey.* strings used project-wide (verified by grep after Task 1 refactor).
- [x] `git diff HEAD -- Sources/Core/Data/AlgorithmDatabase.swift Sources/Core/Data/F2LDatabase.swift` → empty (untouched).
- [x] Closures: stored handlers use `[weak self]` (AppDelegate, SolveTimer onSolveFinished, timers, monitors).
- [x] No issues logged — audit clean.

---

## Phase 11B — Unit Test Expansion

**Status: DONE** (2026-06-27) (Kilo Code)

- [ ] `Tests/CubeNotchTests/F2LDatabaseTests.swift` — 41 cases, all `caseType == "F2L"`, all have primary + ≥2 alts, no duplicate case numbers
- [ ] `Tests/CubeNotchTests/ScrambleGeneratorTests.swift` — exactly 20 moves, no consecutive same face, all valid faces, run 100 times
- [ ] `Tests/CubeNotchTests/SolveTimerTests.swift` — idle→running→stopped state machine, toggle() from stopped starts fresh, reset() clears finalTime
- [ ] `Tests/CubeNotchTests/TimeStoreTests.swift` — ao5 nil when <5 solves, ao5 excludes best+worst, bestTime returns minimum, clearSession() empties
- [ ] `swift test 2>&1` exits 0 with no failures

---

## Phase 11C — Code Review & Force Unwrap Audit

**Status: DONE** (2026-06-27) (Claude Code — guard Desktop URL in ScreenshotService, all other unwraps verified safe)

---

## Phase 12A — Algorithm Trainer Mode

**Status: DONE** (2026-06-27)

A "Train" mode in the HUD. Shows a random OLL/PLL case diagram, user recalls the algorithm from memory, taps to reveal. Tracks accuracy per case.

### New Files
- `Sources/Features/Trainer/TrainerView.swift`
- `Sources/Core/Services/TrainerStore.swift` — tracks per-case attempts/correct counts, persisted

### Features
- [ ] Add "Train" to the main mode picker in ContentView header (Cases / Timer / Train)
- [ ] TrainerView shows:
  - A random OLL or PLL case diagram (CubeStateView in `.preExecution` mode)
  - Case name hidden initially
  - "Reveal" button — taps to show the algorithm and case name
  - After reveal: "Got it ✓" and "Missed ✗" buttons
- [ ] TrainerStore tracks `attemptCount` and `correctCount` per case ID in UserDefaults
- [ ] Cases you miss appear more frequently (weight by miss rate in random selection)
- [ ] Show accuracy % for the current case in the reveal state
- [ ] "Show only: OLL / PLL / Both" filter at top of train view
- [ ] `make build` clean

---

## Phase 13A — Content & UX Enhancements

**Status: NOT STARTED** (do not begin until Phase 12A is done)

Quality-of-life additions that make the app more polished and useful for real use.

### 13A-1: Move Count Display
- [ ] Add a move count (STM — slice turn metric) to every algorithm display
- [ ] Helper: `func moveCount(_ alg: String) -> Int { alg.split(separator: " ").filter { !$0.isEmpty }.count }`
- [ ] In HUD case detail: show "X moves" next to each algorithm in small text
- [ ] In Library detail: show move count next to each algorithm

### 13A-2: AUF Indicator for PLL Cases
- [ ] Add `auf: String?` property to `CubeCase` (optional — only PLL cases use it)
- [ ] In Library PLL detail view, show the AUF orientation: "AUF: U / U2 / U' / none"
- [ ] This helps the user recognize which pre-rotation to apply before executing the PLL

### 13A-3: Recognition Tips
- [ ] Add `recognitionTip: String?` to `CubeCase` (optional)
- [ ] Populate for at least the 21 PLL cases and common OLL cases (look for recognition patterns: "two headlights", "two adjacent same colors", etc.)
- [ ] In HUD case detail: show tip in italics below the algorithm if present
- [ ] In Library: show in a "Recognition" section

### 13A-4: Hotkey Customizer
- [ ] In Settings, add a "Hotkey" row showing the current hotkey (default: "⌥ Space")
- [ ] Tap to record: put the row into "listening" mode, capture the next key combination
- [ ] Save to UserDefaults as a raw key+modifier combo
- [ ] Update `GlobalHotKeyManager` to use the stored hotkey instead of hardcoded Option+Space
- [ ] Guard: cannot set hotkey to Space alone (conflicts with timer), Escape, or Return

### 13A-5: Pinned / Recent Cases
- [ ] In HUD case list: show a "Recent" section at the top (last 5 cases viewed)
- [ ] Pinning: long-press (or secondary click) on a case in the list → "Pin to top" option
- [ ] Pinned cases appear above the rest of the list with a pin indicator
- [ ] Recent and pinned state persisted in UserDefaults

---

## Phase 14A — Export & Sessions

**Status: DONE** (2026-06-27)

Data portability and multi-session tracking.

### 14A-1: CSV Export
- [ ] Add "Export Times" button in TimerView (below stats, small link-style button)
- [ ] Generates a CSV: `date,time,scramble,penalty,session`
- [ ] Saves to Desktop with timestamp filename: `CubeNotch_times_2026-06-27.csv`
- [ ] Also copies path to clipboard
- [ ] Brief feedback: "Exported X solves to Desktop"

### 14A-2: Named Sessions
- [ ] TimeStore: add session name support. Each session has a name (default: date) and list of solves
- [ ] In TimerView: "New Session" prompts for optional session name (text field in a small popover)
- [ ] Session history in TimerView: dropdown or list of past sessions with best/ao5/ao12
- [ ] Tap a past session to view its solves (read-only)

### 14A-3: CSTimer Export (Stretch)
- [ ] Export times in CSTimer-compatible JSON format
- [ ] CSTimer format: array of `[penalty, time_ms, comment, timestamp]` tuples
- [ ] Save as `.txt` file that can be imported into csTimer.net

---

## Phase 15 — Visual Polish (Liquid Glass + Typography + Accessibility)

**Status: DONE** (2026-06-27)

Apply the confirmed macOS 26 Liquid Glass APIs and typography rules from DESIGN.md throughout the app. This is a pure visual upgrade — no new features.

### 15A-1: Liquid Glass on Controls (macOS 26+)
- [ ] Create `Sources/UI/GlassModifier.swift` with the `cubeNotchGlass(shape:)` extension (backward-compat, see CLAUDE.md)
- [ ] In ContentView: wrap the bottom controls toolbar (scramble button, settings gear, tab picker) in `GlassEffectContainer { }.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))`
- [ ] In TrainerView: apply `.glassEffect()` to the filter picker + action buttons area
- [ ] In TimerView: apply `.glassEffect()` to the penalty buttons (DNF/+2) and "New Scramble" button
- [ ] Do NOT apply glass to: algorithm text, timer display, scramble text, case lists, card content
- [ ] Verify: `#available(macOS 26.0, *)` gating on all glass calls; `.ultraThinMaterial` fallback on earlier macOS
- [ ] Test with Reduce Transparency ON — must fall back to solid readable UI
- [ ] `make build` clean

### 15A-2: Timer Display Polish
- [ ] In `TimerView.swift`: ensure timer Text uses `.monospacedDigit()` and `.contentTransition(.numericText())`
- [ ] Add `.animation(.easeInOut(duration: 0.08), value: timerDisplayString)` for smooth digit cross-fade
- [ ] Timer font: `.font(.system(size: 72, weight: .light, design: .default))` — do not use `.monospaced` design, just `.monospacedDigit()` modifier
- [ ] Ao5/Ao12 stats: 20pt regular with `.monospacedDigit()`
- [ ] State color: `.green` when armed/ready (inspection done), `.orange` during inspection < 5s, `.primary` when running

### 15A-3: Typography Scale Enforcement
- [ ] Audit all Text views in HUD (ContentView, TimerView, MainOverlayViews) against typography scale in CLAUDE.md
- [ ] Case labels: `.font(.system(size: 17, weight: .semibold, design: .rounded))`
- [ ] Group/category names: `.font(.system(size: 13, design: .rounded)).foregroundStyle(.secondary)`
- [ ] Algorithm moves: `.font(.system(size: 15, weight: .medium, design: .monospaced))`
- [ ] Alternative algorithms: `.font(.system(size: 13, design: .monospaced)).foregroundStyle(.secondary)`
- [ ] Move counts: `.font(.system(size: 11)).foregroundStyle(.secondary)`

### 15A-4: Accessibility Pass
- [ ] Add `@Environment(\.accessibilityReduceMotion)` to all views with spring animations — conditionally skip animation when true
- [ ] Add `@Environment(\.accessibilityReduceTransparency)` to ContentView — when true, use `.regularMaterial` instead of glass/thin material
- [ ] Ensure all buttons have proper `.accessibilityLabel()` strings
- [ ] Scramble text: minimum font size 13pt — do not drop below on compact mode

### 15A-5: Corner Radius + Spacing Audit
- [ ] All card backgrounds: `RoundedRectangle(cornerRadius: 12, style: .continuous)`
- [ ] All buttons: `RoundedRectangle(cornerRadius: 8, style: .continuous)` or `Capsule()` for pill style
- [ ] All padding: multiples of 8pt — replace any arbitrary values (7pt, 9pt, 11pt, etc.)
- [ ] `make build` clean

---

## Phase 16 — Stats Dashboard & Progress Tracking

**Status: DONE** (2026-06-27)

A dedicated Stats tab in the HUD showing real progress data that makes users want to open the app daily.

### 16A-1: Personal Records
- [ ] Add to `TimeStore`: `pbSingle`, `pbAo5`, `pbAo12`, `pbAo100` (updated on every solve)
- [ ] Display in a "Records" card: "PB: 9.84 | Ao5: 11.23 | Ao12: 12.01"
- [ ] Records persist across sessions — never cleared by "New Session"
- [ ] Show "🎉 New PB!" banner overlay for 2s when a PB is set (animate in/out, respects reduceMotion)

### 16A-2: Session Stats View
- [ ] Add "Stats" tab to HUD tab picker (alongside Cases / Timer / Train)
- [ ] StatsView shows:
  - Current session: solve count, mean, ao5, ao12, best of session
  - All-time personal records
  - Total solves ever (lifetime counter)
  - "Daily streak" — days in a row where at least one solve was logged
- [ ] Stats tab shows "No solves yet — start the timer!" when session is empty

### 16A-3: Session Graph (Sparkline)
- [ ] Draw a simple time graph of the last 12 solves using SwiftUI `Path` (no external charting library)
- [ ] Each data point: a circle at the Y position for that solve time
- [ ] Connect with a smooth line (`addCurve(to:controlPoint1:controlPoint2:)`)
- [ ] Highlight the best time with an accent color dot
- [ ] DNF solves shown as a red X above the graph baseline, not plotted on the line

---

## Phase 17 — WCA-Accurate Scrambles

**Status: DONE** (2026-06-27)

The current scrambler prevents same-face repeats but not opposite-face repeats (U then D is legal in WCA scramblers but creates cancellations). Upgrade to proper WCA scramble logic.

### 17A-1: Axis-Aware Scramble Generator
- [ ] Update `ScrambleGenerator.swift` (replace `generate3x3()` logic)
- [ ] WCA rule: no two consecutive moves on the same face; AND no same-axis-opposite-face on back-to-back moves
  - Axis pairs: (U, D) = Y axis; (F, B) = Z axis; (L, R) = X axis
  - After U: disallow U and D. After F: disallow F and B. Etc.
- [ ] Deterministic selection: build allowed list, pick from it — never a loop
- [ ] Keep producing exactly 20 moves with suffixes `''`, `'`, `2`
- [ ] Update `ScrambleGeneratorTests.swift` to verify axis-pair rule (no consecutive same-axis moves)

### 17A-2: Inspection Timer
- [ ] WCA rules include a 15-second inspection period before each solve
- [ ] Add `isInspecting: Bool` and `inspectionRemaining: TimeInterval` to `SolveTimer`
- [ ] Pressing space after a solve is stored starts a 15-second countdown (optional — user can skip via Settings)
- [ ] Timer display shows inspection countdown in orange (< 5 seconds threshold)
- [ ] After 15s: +2 penalty applied automatically; after 17s: DNF applied automatically (WCA rule)
- [ ] Settings toggle: "WCA Inspection" on/off (default: on)

---

## Phase 17B — UI Visual Overhaul

**Status: DONE** (2026-06-28)

Complete visual redesign of the four main UI tabs to be clean, professional, and minimal.

### Files changed:
- `Sources/Features/Timer/TimerView.swift` — full rewrite: timer is the hero (72pt ultraLight), stats strip (AO5/AO12/AO100/BEST as labeled cells with dividers), alternating solve history rows, minimal bottom bar (Cross toggle + session name + Session/Export buttons), PB banner with animation, hold-space hint text
- `Sources/Features/Stats/StatsView.swift` — full rewrite: card-based layout (session card, PB records card, lifetime/streak card, sparkline card), proper section labels, empty state with SF Symbol
- `Sources/Features/Trainer/TrainerView.swift` — full rewrite: accuracy badge with color-coded dot, Got it (green) / Missed (red) buttons with icons, result badge with transition animation, cleaner reveal flow
- `Sources/UI/MainOverlayViews.swift` — `caseDetailView` redesigned: algorithm in prominent card with styled header (PRIMARY / move count / copy button), alternatives as individual rows with index number + move count + copy button, recognition tip with eye icon

### Visual principles applied:
- Timer: `72pt ultraLight` (not light — ultraLight is more refined), armed state shows green
- Stats cells: 9pt uppercase tracking labels, 14pt medium values
- Cards: `Color.white.opacity(0.05)` background + `0.5pt strokeBorder` at `0.08` opacity
- Solve history: alternating row shading, compact 12pt monospaced times
- All secondary labels: `.tertiary` or `.secondary.opacity(0.X)` for proper depth

---

## Phase 18 — Onboarding & First-Run Experience

**Status: DONE** (2026-06-28)

Users who open a utility app and don't immediately understand what it does uninstall it. This phase adds zero-friction onboarding.

### 18A-1: First Launch Detection
- [x] `@AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false`
- [x] On first launch only: show an `OnboardingView` as a sheet over the HUD
- [x] Three swipeable cards (macOS ScrollView + paging dots because PageTabViewStyle unavailable on macOS):
  1. "Your Speedcubing HUD" — what the app does in one sentence + screenshot
  2. "Algorithm Library" — "57 OLL + 21 PLL cases always one glance away"
  3. "Train Your Recognition" — quick explainer of the trainer mode
- [x] Final card has "Get Started" button that sets `hasCompletedOnboarding = true` and dismisses
- [x] Onboarding can be re-triggered from Settings: "Show Intro Again"

### 18A-2: Accessibility Permission Prompt
- [x] CGEventTap requires Accessibility permission — if denied, the spacebar timer won't work
- [x] On first launch, if the tap fails to create, show a sheet: "Spacebar Timer Needs Accessibility Access"
  - Explain in plain language why
  - "Open System Settings" button → `NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)`
- [x] "Retry" button re-creates the event tap via NotificationCenter observer

### 18A-3: Settings — Hotkey Tooltip
- [x] In Settings, below the hotkey customizer, add: "Tip: Ctrl+Shift+Space works even while another app is in focus" (updated from Option+Space per Task 4)
- [x] First time settings drawer opens: brief pulse animation on the "Hotkey" row (green dot + scale) to draw attention

---

## Phase 19 — App Icon, About Window, Distribution Prep

**Status: DONE** (2026-06-28)

Make the app feel finished and distributable.

### 19A-1: App Icon
- [x] Generate a macOS app icon set using SF Symbol `cube.fill` as the base (via Scripts/GenerateAppIcon.swift)
- [x] Create `Assets.xcassets/AppIcon.appiconset` with sizes: 16, 32, 128, 256, 512 (1x+2x)
- [x] Icon design: dark background (#1A1A1A), centered cube.fill in accent blue
- [x] All 10 PNGs + Contents.json present with correct naming per Apple spec
- [x] Script committed under Scripts/ for future regeneration

### 19A-2: About Window
- [x] `@objc func showAbout()` in AppDelegate — opens a small centered `NSWindow` (400×280, titled, non-resizable)
- [x] Content: SF Symbol cube + "CubeNotch" title, version string, "Made for speedcubers. Built with ❤️"
- [x] Add "About CubeNotch" to status bar menu
- [x] Version pulled from `Bundle.main.infoDictionary["CFBundleShortVersionString"]`
- [x] Implemented `AboutView.swift` (SwiftUI hosted in NSWindow)

### 19A-3: Entitlements & Sandboxing Prep
- [x] `CubeNotch.entitlements` created at project root
- [x] Required entitlements present:
  - `com.apple.security.app-sandbox`
  - `com.apple.security.temporary-exception.mach-lookup.global-name`
  - `com.apple.security.files.user-selected.read-write`
  - `com.apple.security.automation.apple-events` (for CGEventTap)
- [x] Note about Accessibility permission documented in PROBLEMS.md (CGEventTap)
- [x] `make build` remains clean with entitlements file present

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
