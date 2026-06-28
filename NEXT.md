# NEXT — Current Task for Agents

> Read this file first, then read CLAUDE.md, AGENTS.md, and TASKS.md before touching any code.
> Run `make build` after every phase. Fix all errors before moving to the next phase.
> Update this file when a phase is complete: mark it done and set the next phase as current.

---

## Phase 5A — Positions & Spring Animation

**Status: DONE** (2026-06-27)

- [x] Added `notch` and `bottomCenter` to `Anchor` enum
- [x] Positioning math for notch (top-center, notch-safe) and bottomCenter
- [x] Spring animations via `NSAnimationContext` + cubic-bezier (ease-in-out with overshoot) for glide on show/hide
- [x] Double-click anywhere on overlay triggers spring hide (slides to anchor edge)
- [x] Anchor picker shows all 6 positions (Top Left/Right, Bottom Left/Right, Notch, Bottom Center)
- [x] Monitor picker: lists `NSScreen.screens`, persists `@AppStorage("preferredScreen")`, used for positioning

---

## Phase 6A — Scramble Generator

**Status: DONE** (2026-06-27)

- [x] Created `Sources/Features/Timer/ScrambleGenerator.swift`
- [x] `generate3x3()` produces exactly 20-move WCA-style scrambles (U D F B L R + ' 2, no consecutive same face)
- [x] `make build` clean
- [x] No changes to AlgorithmDatabase.swift

---

## Phase 6B — Built-in Timer

**Status: DONE** (2026-06-27)

- [x] SolveTimer.swift (ObservableObject): idle/running/stopped, scramble, formatted elapsed, start/stop/reset/toggle, live 60fps updates
- [x] TimerView.swift: scramble display, large monospace time, New/Start-Stop/Reset buttons, "Spacebar starts/stops" hint
- [x] Mode switch in main overlay header: Cases ↔ Timer (replaces old segmented when not in detail)
- [x] Global CGEventTap spacebar: only consumes when window visible + timer tab active + idle/running; never steals in other apps
- [x] Wired via @EnvironmentObject into ContentView + TimerView
- [x] make build clean

---

## Phase 6C — Time History

**Status: DONE** (2026-06-27)

- [x] TimeStore.swift (ObservableObject): persists solves via UserDefaults, exposes ao5/ao12/ao100 + best, clearSession()
- [x] Auto-save on timer stop via SolveTimer.onSolveFinished
- [x] Timer tab shows: ao5/ao12/ao100 stats, recent 10 solves (time + scramble prefix), New Session button
- [x] make build clean

---

## Phase 6D — Cross Practice Mode

**Status: DONE** (2026-06-27)

- [x] Cross practice toggle in TimerView
- [x] generateCrossPractice() helper (same generator)
- [x] crossSolveCount incremented on stop when cross mode active
- [x] "Cross solves this session" label
- [x] make build clean

---

## Phase 7A — Screenshot

**Status: DONE** (2026-06-27)

- [x] ScreenshotService.swift using CGWindowListCreateImage on the overlay window
- [x] Saves PNG to Desktop with timestamp
- [x] Copies to clipboard
- [x] Camera button in header (visible in list/timer modes)
- [x] Brief "Saved" feedback label
- [x] make build clean (deprecation warning noted, functional)

---

## Phase 7B — F2L Data

**Status: DONE** (2026-06-27)

- [x] Created separate `Sources/Core/Data/F2LDatabase.swift` (protected AlgorithmDatabase.swift untouched)
- [x] 41 F2L cases with primary + ≥2 alternatives each (caseType "F2L")
- [x] Added F2L | OLL | PLL segmented picker in browser (visible in Cases mode)
- [x] `make build` clean (full project)
- [x] No modifications to AlgorithmDatabase.swift

---

## UP NEXT

All planned phases from NEXT.md (5A through 7B) are complete.

Future work (as listed in NEXT.md):
- Research / Market phases (RESOURCES.md, MARKET.md, iOS concept)
- Long-term Library Mode, more subsets, favorites, iCloud, etc.

- **Phase 6A** — Scramble generator (`Sources/Features/Timer/ScrambleGenerator.swift`, WCA-valid 20-move 3x3 scrambles)
- **Phase 6B** — Built-in timer (`SolveTimer.swift`, `TimerView.swift`, spacebar via CGEventTap, Timer tab in UI)
- **Phase 6C** — Time history (`TimeStore.swift`, ao5/ao12/ao100, session management)
- **Phase 6D** — Cross practice mode (scrambles + cross solve tracking in Timer tab)
- **Phase 7A** — Screenshot (CGWindowListCreateImage, save to Desktop + clipboard)
- **Phase 7B** — F2L data (41 cases added to AlgorithmDatabase.swift, F2L tab in browser)

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

## iOS APP RESEARCH PHASE (separate from coding — use Claude Code or Grok DeepSearch)

**Goal:** Research the market for a "Learn to Solve a Rubik's Cube" iOS app with a dual-purpose angle (beginners learn, then stay for algorithm reference).

**Search for:**
- Existing "learn to solve Rubik's cube" iOS apps — ratings, reviews, revenue estimates, what users hate about them
- How structured daily-learning apps (Duolingo-style) perform on the App Store in niche topics
- Search volume for "how to solve a rubik's cube" (Google Trends, App Store search)
- Whether free + ads or freemium works better for this category
- iOS App Store cubing app landscape — any gaps or underserved angles
- Reddit (r/Cubers, r/Rubiks) posts asking for app recommendations — what are people asking for that doesn't exist

**Output:** Append findings to MARKET.md under a new "iOS App Concept" section.

---

## MARKET RESEARCH PHASE (separate from coding — use Claude Code or Grok DeepSearch)

**Goal:** Research whether this app has real commercial potential, who the target users are, how to reach them, and how to make money from it.

**Search for:**
- Size of the speedcubing community (WCA registered competitors, active hobbyists, YouTube/Reddit/Discord audience)
- Existing competing apps on Mac App Store — what do they charge, how many reviews, what's missing
- What speedcubers currently complain about in their tools (Reddit: r/Rubik's, r/Cubers, Speedsolving.com forums)
- Pricing models that work for niche Mac utilities (one-time purchase vs subscription vs freemium)
- Mac App Store vs direct distribution (Gumroad, Paddle, own website) — fees, discoverability, pros/cons
- Whether top cubers or YouTubers (JPerm, CubeSkills, etc.) do sponsorships or promotions for tools
- Any Kickstarters, Patreons, or indie dev success stories in the cubing tool niche
- App Store optimization keywords for speedcubing apps

**Output:** Add a `MARKET.md` file with: honest assessment of market potential, recommended monetization model, suggested price point, and top 3 marketing channels to pursue.

---

## LONG-TERM VISION — Full Speedcubing Library App

The app has two modes that coexist:

**HUD Mode** (current focus): floating borderless overlay, compact, non-activating, for use during active solving sessions on top of a timer.

**Library Mode** (future): a full native Mac window that opens on demand — organized, comprehensive, beautiful. The goal is to be the macOS equivalent of SpeedCubeDB: a one-stop-shop for all CFOP algorithm sets, organized by method and subset.

### Library Mode should eventually contain:
- **CFOP full coverage:** Cross, F2L (41 cases), OLL (57 cases), PLL (21 cases)
- **Advanced subsets:** ZBLL, COLL, CMLL, OLLCP, Winter Variation, VLS, HLS, WVLS
- **Other methods:** Roux, ZZ, Petrus — at minimum as reference
- **Each case:** primary algorithm, community alternatives, fingertrick notes, diagram, recognition tips
- **Search & filter:** by case name, AUF, recognition pattern, subset
- **User customization:** mark favorites, set personal best algorithm per case, track learning progress
- **Algorithm comparison:** side-by-side view of alternatives with move count

### Architecture note for future agents:
- HUD mode uses the existing FloatingOverlayWindow (NSPanel, non-activating, compact)
- Library mode opens a standard NSWindow (activating, resizable, full chrome)
- Both read from the same AlgorithmDatabase — never duplicate data
- Library mode is a separate window controller, not a resize of the HUD

---

## RULES (always apply)
- Never modify or remove existing OLL/PLL cases in AlgorithmDatabase.swift
- Window must remain non-activating at all times except global hotkeys (CGEventTap)
- Spring animations on all show/hide transitions — no linear easing
- All new files go in the correct Sources/ subfolder per AGENTS.md directory layout
