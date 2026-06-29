# CubeNotch — Handoff Document
_Last updated: 2026-06-28_

## What the app is
Floating macOS HUD overlay for speedcubers. Stays on top of all apps, non-activating (never steals focus). Option+Space (or Ctrl+Shift+Space after Task 4 below) toggles it. Global spacebar starts/stops the timer from any app.

## Current build state
- `swift build` — clean, zero errors
- `swift test` — 24/24 passing
- Last commit: `e0eb952` — bug fixes from audit
- GitHub: https://github.com/qwertyuiop97/CubeApp

## Architecture
- `Sources/App/AppDelegate.swift` — window setup, CGEventTap spacebar, hotkey, status bar menu
- `Sources/App/FloatingOverlayWindow.swift` — NSPanel subclass, spring animations, anchor positioning
- `Sources/UI/MainOverlayViews.swift` — ContentView (ALL HUD UI lives here, NO ContentView.swift)
- `Sources/UI/GlassModifier.swift` — cubeNotchGlass() backward-compat Liquid Glass extension
- `Sources/Features/Timer/SolveTimer.swift` — timer state machine, inspection, arm/disarm
- `Sources/Features/Timer/TimeStore.swift` — solve history, ao5/ao12, PBs, CSV/CSTimer export
- `Sources/Features/Timer/TimerView.swift` — timer UI
- `Sources/Features/Trainer/TrainerView.swift` — flashcard trainer UI
- `Sources/Core/Services/TrainerStore.swift` — weighted random, accuracy tracking
- `Sources/Features/Stats/StatsView.swift` — stats tab, sparkline
- `Sources/Features/Library/LibraryView.swift` — full window library (NSWindowController)
- `Sources/Core/Data/AlgorithmDatabase.swift` — PROTECTED. 57 OLL + 21 PLL cases. Never modify.
- `Sources/Core/Data/F2LDatabase.swift` — PROTECTED. 41 F2L cases. Never modify.
- `Sources/Core/Data/BeginnerMethodDatabase.swift` — 7 LBL steps.
- `Sources/Core/Services/CubeStateManager.swift` — size mode, anchor, screen, notifications
- `Sources/Core/Services/UserDefaultsKeys.swift` — UDKey enum (currently unused everywhere, Task 1 fixes this)
- `Sources/Features/CubeDisplay/CubeStateView.swift` — 2D cube diagram (needs improvement, see below)

## Features complete
### Timer
- Global spacebar via CGEventTap (intercepts before any other app)
- Hold-to-arm NOT YET DONE (Task 3 below — current behavior is instant tap)
- WCA 15s inspection countdown, orange <5s, +2 at 15s, DNF at 17s
- ao5/ao12/ao100 (WCA-correct trimmed mean, DNF-aware)
- Named sessions, session history
- PB tracking (single/ao5/ao12) with "New PB!" banner
- CSV export to Desktop, CSTimer JSON export

### Algorithm Library (HUD)
- F2L (41) / OLL (57) / PLL (21) cases
- Move count on every algorithm
- Copy to clipboard
- Search, recent cases (last 5), pinned cases (right-click)
- Random shuffle

### Library Window
- Full native Mac window, sidebar + detail pane
- Favorites, "My Algorithm" per case, keyboard nav

### Trainer
- Flashcard OLL/PLL/Both, weighted random by miss rate
- Accuracy tracked per case in UserDefaults

### Stats
- Session stats, lifetime count, streak, sparkline chart

### Settings
- Blur slider, background tint (6 options)
- 6 anchor positions, 3 size modes, multi-monitor
- Hotkey customizer (record any combo)
- WCA inspection toggle
- Launch at login

### Visual
- Liquid Glass on controls (macOS 26+), ultraThinMaterial fallback
- Reduce Motion + Reduce Transparency respected

## KNOWN ISSUES / REMAINING WORK

### Critical UX (not yet implemented)
- **Cube diagrams look wrong** — CubeStateView uses a heuristic to generate sticker colors, NOT real per-case data. Diagrams don't match actual OLL/PLL patterns. See Task 5 in the Kilo Code prompt.
- **Hold-to-arm spacebar not done** — currently instant tap. Task 3 implements proper stackmat-style hold behavior.

### Pending Kilo Code tasks (send this prompt verbatim):

```
Read NEXT.md, CLAUDE.md, and DESIGN.md before touching any code.
Work through these tasks in order. After each: swift build (zero errors), swift test (24/24 pass), git add Sources/ NEXT.md + git commit. No batch commits.
ContentView is in Sources/UI/MainOverlayViews.swift — there is no ContentView.swift.

TASK 1 — Adopt UDKey everywhere
UDKey enum exists at Sources/Core/Services/UserDefaultsKeys.swift but is never used.
Add missing keys to UDKey: "wcaInspection", "customHotKeyCode", "customHotKeyMods", "cubeNotchTrainerStats", "cubeNotchSessions", "cubeNotchCurrentSession", "cubeNotchPersonalBests", "cubeNotchLifetimeSolves", "cubeNotchSolveDates", "timerPrecision", "hideAosDuringSolve", "autoCopyScramble", "inspectionDuration"
Replace every raw UserDefaults string literal in ALL Swift files with UDKey.* references.
Commit: "Task 1: adopt UDKey enum across all UserDefaults call sites"

TASK 2 — Notch anchor window level
File: Sources/App/FloatingOverlayWindow.swift
Add: func updateLevel(for anchor: Anchor) { self.level = anchor == .notch ? .statusBar : .floating }
Call it inside positionAtAnchor() and animatedShowTo() after setting the frame.
Commit: "Task 2: use .statusBar window level for notch anchor"

TASK 3 — Hold-to-arm spacebar timer
PROBLEM: bare spacebar swallowed by CGEventTap breaks typing in Chrome and other apps. Real stackmat timers require holding space to arm first.
NEW BEHAVIOR: Hold space 0.4s → arms (green). Release while armed → starts. Tap space while running → stops instantly. Release before 0.4s → passes through to other app.

1. Sources/Features/Timer/SolveTimer.swift:
   Add @Published var isArmed: Bool = false
   Add func arm() { guard state == .idle else { return }; isArmed = true }
   Add func disarm() { isArmed = false }
   Add func startFromArm() { guard isArmed, state == .idle else { return }; isArmed = false; reset(); start() }
   toggle() when state == .running still stops immediately (unchanged)
   toggle() when state == .idle should do nothing (arm/startFromArm handle idle start)
   toggle() when state == .stopped: reset to idle (unchanged)

2. Sources/App/AppDelegate.swift:
   Change CGEventTap mask to include keyUp: let mask = CGEventMask(1 << CGEventType.keyDown.rawValue) | CGEventMask(1 << CGEventType.keyUp.rawValue)
   Add private var armWorkItem: DispatchWorkItem? as stored property on AppDelegate.
   In handleKeyEvent:
     Space keyDOWN + not repeat + window visible + timer tab active + state == .idle:
       Cancel existing armWorkItem. Create new DispatchWorkItem { [weak self] in self?.solveTimer?.arm() }. Schedule on DispatchQueue.main after 0.4s. Store it. Return nil (consume).
     Space keyUP + timer tab active:
       If solveTimer.isArmed → call solveTimer.startFromArm(), return nil.
       Else → cancel armWorkItem, return Unmanaged.passUnretained(event) (pass through).
     Space keyDOWN + state == .running → call toggle() to stop, return nil. No hold needed to stop.
     Space keyDOWN + isInspecting → existing inspection behavior unchanged.

3. Sources/Features/Timer/TimerView.swift:
   When timer.isArmed: show "Release to start" in green below the time.
   When timer.state == .idle and not armed: show "Hold Space" in .secondary below the time.
Commit: "Task 3: hold-to-arm spacebar — 0.4s hold arms timer, release starts, prevents accidental triggers"

TASK 4 — Change default hotkey to Ctrl+Shift+Space
Option+Space conflicts with Alfred, Raycast, and many other Mac apps.
File: Sources/Core/Services/GlobalHotKeyManager.swift
In registerDefault(): change modifiers from UInt32(optionKey) to UInt32(controlKey | shiftKey) — controlKey=4096, shiftKey=512, combined=4608. keyCode stays 49.
Update AppDelegate setupStatusItem() toolTip from "Option+Space" to "Ctrl+Shift+Space".
Update any display strings showing "⌥ Space" to "⌃⇧Space".
Commit: "Task 4: default hotkey Ctrl+Shift+Space — avoids Alfred/Raycast conflicts"

TASK 5 — Fix cube diagram layout and accuracy
CURRENT PROBLEM: CubeStateView draws side strips in a horizontal row BELOW the U face. Looks nothing like JPerm, SpeedCubeDB, or VisualCube. Colors are generated by a heuristic, not real per-case data.
TARGET: Standard "plan view" — U face centered with 4 side strips on each edge in a cross shape:
          [B strip]
[L strip] [U face ] [R strip]
          [F strip]

PART A — Fix layout in Sources/Features/CubeDisplay/CubeStateView.swift:
Replace drawLastLayer() to position side strips on the 4 edges of the U face (not in a row below).
B strip directly above U face top edge. R strip to the right. L strip to the left. F strip below.
Each side strip: 3 stickers wide × 1 sticker tall. Keep black stroke between stickers. Remove F/R/B/L labels.

PART B — Create Sources/Core/Data/StickerDatabase.swift:
struct StickerPattern { var uFace: [Bool]; var frontTop: [Color]; var rightTop: [Color]; var backTop: [Color]; var leftTop: [Color] }
static func pattern(for caseID: String) -> StickerPattern?

OLL: uFace = which stickers are yellow (true/false), all side strips = Color(white:0.3) (color neutral)
PLL: uFace = all true, side strips = actual permuted colors (F=red R=green B=orange L=blue base)

OLL uFace patterns (9 bools, position 0=top-left to 8=bottom-right):
OLL-1:  F,F,F,F,T,F,F,F,F  OLL-2:  F,F,F,F,T,F,F,F,F  OLL-3:  F,T,F,F,T,F,F,F,F
OLL-4:  F,F,F,F,T,F,F,T,F  OLL-5:  T,F,F,F,T,F,F,F,T  OLL-6:  F,F,T,F,T,F,T,F,F
OLL-7:  F,F,T,F,T,F,F,F,T  OLL-8:  T,F,F,F,T,F,T,F,F  OLL-9:  F,F,T,F,T,F,T,F,F
OLL-10: T,F,F,F,T,F,F,F,T  OLL-11: F,F,T,T,T,F,F,F,F  OLL-12: F,T,F,F,T,T,F,F,F
OLL-13: F,F,F,T,T,F,F,T,F  OLL-14: F,F,F,F,T,T,F,T,F  OLL-15: F,F,F,F,T,F,F,T,T
OLL-16: F,F,F,F,T,F,T,T,F  OLL-17: F,F,F,T,T,T,F,F,F  OLL-18: F,T,F,F,T,F,F,F,F
OLL-19: F,F,F,F,T,F,F,T,F  OLL-20: F,T,F,F,T,F,F,T,F  OLL-21: T,T,T,T,T,T,T,T,T
OLL-22: T,T,T,T,T,T,T,T,T  OLL-23: T,T,T,T,T,T,T,T,T  OLL-24: F,T,F,T,T,F,F,T,F
OLL-25: F,T,F,F,T,T,F,T,F  OLL-26: T,F,F,T,T,F,T,F,F  OLL-27: F,F,T,F,T,T,F,F,T
OLL-28: F,T,F,F,T,F,F,T,F  OLL-29: F,F,T,F,T,F,T,F,F  OLL-30: T,F,F,F,T,F,F,F,T
OLL-31: F,T,F,F,T,F,T,F,F  OLL-32: F,T,F,F,T,F,F,F,T  OLL-33: F,T,F,T,T,F,F,F,F
OLL-34: F,F,F,T,T,T,F,T,F  OLL-35: T,F,T,F,T,F,F,F,F  OLL-36: F,F,F,F,T,F,T,F,T
OLL-37: F,T,F,F,T,F,T,F,T  OLL-38: T,F,T,F,T,F,F,T,F  OLL-39: T,F,F,T,T,F,F,F,F
OLL-40: F,F,F,F,T,T,F,F,T  OLL-41: F,F,T,F,T,T,F,F,F  OLL-42: F,T,F,T,T,F,F,F,F
OLL-43: F,T,F,F,T,F,F,T,F  OLL-44: F,T,F,T,T,T,F,T,F  OLL-45: F,T,F,T,T,T,F,T,F
OLL-46: T,T,F,T,T,F,F,F,F  OLL-47: F,F,F,F,T,F,F,T,T  OLL-48: F,F,F,T,T,F,T,F,F
OLL-49: T,F,F,T,T,F,F,F,F  OLL-50: F,F,F,F,T,T,F,F,T  OLL-51: T,T,F,F,T,F,F,T,T
OLL-52: F,T,T,F,T,F,T,T,F  OLL-53: T,T,F,T,T,F,T,T,F  OLL-54: F,T,T,F,T,T,F,T,T
OLL-55: T,F,T,T,T,T,F,F,F  OLL-56: F,F,F,T,T,T,T,F,T  OLL-57: T,F,T,T,T,T,T,F,T

PLL side patterns (all uFace=true; base: F=red R=green B=orange L=blue):
PLL-1 (Aa):  F=[R,R,R]  R=[B,G,G]  B=[O,O,G]  L=[B,B,O]
PLL-2 (Ab):  F=[R,R,R]  R=[G,G,O]  B=[B,O,O]  L=[B,B,G]
PLL-3 (E):   F=[R,O,R]  R=[G,R,G]  B=[O,G,O]  L=[B,O,B]
PLL-4 (F):   F=[R,G,O]  R=[B,G,R]  B=[R,O,O]  L=[B,B,G]
PLL-5 (Ga):  F=[O,R,R]  R=[R,G,G]  B=[G,O,O]  L=[B,B,B]
PLL-6 (Gb):  F=[G,R,R]  R=[O,G,G]  B=[R,O,O]  L=[B,B,B]
PLL-7 (Gc):  F=[R,R,O]  R=[G,G,R]  B=[O,O,G]  L=[B,B,B]
PLL-8 (Gd):  F=[R,R,G]  R=[G,G,O]  B=[O,O,R]  L=[B,B,B]
PLL-9 (H):   F=[R,O,R]  R=[G,B,G]  B=[O,R,O]  L=[B,G,B]
PLL-10 (Ja): F=[R,R,R]  R=[G,B,G]  B=[O,O,O]  L=[G,B,B]
PLL-11 (Jb): F=[R,R,R]  R=[B,G,G]  B=[O,O,O]  L=[B,B,G]
PLL-12 (Na): F=[R,O,R]  R=[G,B,G]  B=[O,R,O]  L=[B,G,B]
PLL-13 (Nb): F=[R,O,R]  R=[G,B,G]  B=[O,R,O]  L=[B,G,B]
PLL-14 (Ra): F=[R,R,R]  R=[O,G,G]  B=[G,O,O]  L=[B,B,B]
PLL-15 (Rb): F=[R,R,R]  R=[G,G,B]  B=[O,O,O]  L=[G,B,B]
PLL-16 (T):  F=[R,G,R]  R=[B,G,G]  B=[O,O,O]  L=[B,B,R]
PLL-17 (Ua): F=[O,R,R]  R=[G,G,G]  B=[R,O,O]  L=[B,B,B]
PLL-18 (Ub): F=[G,R,R]  R=[G,G,G]  B=[O,O,O]  L=[B,B,O]
PLL-19 (V):  F=[R,R,O]  R=[G,B,G]  B=[R,O,O]  L=[B,G,B]
PLL-20 (Y):  F=[R,O,R]  R=[G,G,B]  B=[O,R,O]  L=[G,B,B]
PLL-21 (Z):  F=[G,R,G]  R=[R,G,R]  B=[B,O,B]  L=[O,B,O]
(Color abbreviations: R=.red G=.green B=.blue O=.orange)

Wire up: in CubeStateView replace computeStickerState() to use StickerDatabase.pattern(for: currentCase.id). Map uFace Bool → Color: true=.yellow, false=Color(white:0.25,opacity:1). Fall back to current heuristic if pattern not found.
Commit: "Task 5: accurate cross-layout cube diagrams with real OLL/PLL sticker patterns"

STOP after Task 5. Tell me: "Tasks 1–5 complete. Build clean, tests pass."
```

## Research findings (from today)
- **No Swift SPM package for cube diagrams exists.** CubeTime uses the same Rectangle approach.
- **cubing.js** (MIT, experiments.cubing.net/cubing.js) — could render interactive SVG cube diagrams via WKWebView. Best long-term option for visual quality.
- **CoreRubiksCube** (MIT, github.com/codelynx/CoreRubiksCube) — pure state model, no UI. Could back the diagram rendering with algorithmic correctness.
- **WCA scrambles** — no Swift package. twsearch (Rust, GPL) via Process is the best path if needed. Current scrambler is "good enough" for practice.
- **Algorithm databases** — none permissive. AlgorithmDatabase.swift is already as good as what's publicly available.

## What still needs human decisions
- App icon (need actual design)
- Distribution: direct download or App Store (CGEventTap conflicts with App Store sandbox)
- Pricing
- How to reach speedcubing community (JPerm, Discord, Reddit)

## NEXT.md status
Phases 5A through 17A: DONE
Tasks 1–5 above: NOT STARTED (pending Kilo Code run)
Phase 18 (onboarding): NOT STARTED
Phase 19 (app icon, about window, distribution): NOT STARTED
