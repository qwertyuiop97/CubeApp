# CubeApp — Autonomous Completion Prompt (Z Code, no interruptions)

Run in ~/Projects/CubeApp until DONE. Do not ask questions. Do not stop for progress reports. Do not stop between phases. Only stop when: `swift build` is clean, `swift test` passes, and all items below are complete. If blocked on one item, log it in PROBLEMS.md and continue to the next independent item.

## 0. Startup (read once, then code)
1. `git status --short`
2. Read HANDOFF.md (Tasks 1-5 specs are normative), NEXT.md, CLAUDE.md, DESIGN.md, AGENTS.md
3. Confirm protected files untouched: Sources/Core/Data/AlgorithmDatabase.swift (57 OLL + 21 PLL, each primary + ≥2 alts), Sources/Core/Data/F2LDatabase.swift (41 cases). Never invent algorithms. Never hardcode alg strings in views.

## 1. Algorithm integrity (critical — past model hallucinated algs)
- The bug: a prior run generated algorithms from scratch instead of using published ones. This must never happen again.
- For every case in AlgorithmDatabase + F2LDatabase + BeginnerMethodDatabase:
  - Cross-check primary algorithm against at least 2 trusted public sources (SpeedCubeDB.net, JPerm.net, AlgDb.net, CubeSkills, WCA / cubing.js datasets). Use web fetch.
  - Valid notation only: U U' U2 D D' D2 R R' R2 L L' L2 F F' F2 B B' B2, wide (r, Rw), rotations (x y z), M E S + variants. No made-up tokens.
  - If a case mismatches all sources: DO NOT silently overwrite. Leave the data as-is, add a PROBLEMS.md entry with caseID + current string + what sources say, status pending, and continue.
  - Add/extend Tests/ to assert: OLL=57, PLL=21, F2L=41, every case has primary + ≥2 alts, every token parses with your move parser, no empty strings.
- Commit: "Verify algorithm databases against public sources + parser tests"

## 2. Cube visuals — pro quality, not basic drawings
Current CubeStateView heuristic is unacceptable (side strips in a row below U face, wrong colors).
Target: JPerm / SpeedCubeDB / VisualCube standard plan view:
```
      [B strip 3x1]
[L 3x1] [U 3x3] [R 3x1]
      [F strip 3x1]
```
Requirements:
- Create Sources/Core/Data/StickerDatabase.swift with real per-case patterns (HANDOFF.md Task 5 Part B patterns are the starting spec — implement all 57 OLL uFace + 21 PLL side perms exactly).
- Rewrite drawLastLayer() in Sources/Features/CubeDisplay/CubeStateView.swift to cross layout above. 3x1 side strips, black gaps, no F/R/B/L labels, proper sticker radii, correct yellow (#FFD500-ish) vs dim states.
- Colors: U yellow true, dim gray false. PLL sides: F red, R green, B orange, L blue base with permuted patterns from HANDOFF.
- Must scale cleanly across compact/medium/large, respect Reduce Transparency / Reduce Motion.
- Research first: check cubing.js (MIT) via WKWebView vs native Canvas. If native Canvas can hit the quality bar, stay native. If not, spike cubing.js embed for Library detail pane. Do not ship two competing renderers in the HUD — one path only.
- Commit: "Accurate cross-layout cube diagrams with real sticker data"

## 3. Algorithm playback animation (must be very good)
- New: Sources/Features/CubeDisplay/AlgorithmAnimator.swift — given a caseID + algorithm string, animate the diagram move-by-move.
- Behavior: Play/Pause/Step/Reset, speed slider (0.5x–3x), move highlight on current trigger (e.g. sexy-move grouping), progress bar, keyboard: space = play/pause when Library focused (never hijack global HUD spacebar).
- Animation quality: spring/ease stickers transitioning between states, not flickering redraws. 60fps on M1+. Precompute sticker states by actually applying the inverse/forward move sequence to a cube model — never hand-tween colors.
- Wire into both HUD caseDetailView (compact inline player) and Library detail pane (large player).
- Commit: "Algorithm playback animator with step + speed + trigger highlight"

## 4. Finish HANDOFF Tasks 1-5 verbatim
Tasks 1 (UDKey), 2 (notch level), 3 (hold-to-arm 0.4s), 4 (Ctrl+Shift+Space default), 5 (diagrams) — specs at HANDOFF.md:80-202. After each: swift build clean, swift test pass, separate git commit with the message given. STOP asking after Task 5 — continue to section 5.

## 5. Definition of done (verify all before exiting)
- `swift build` zero errors, zero warnings introduced
- `swift test` all pass (include new parser + pattern + animator tests)
- App launches, HUD shows/hides on hotkey, never steals focus, timer hold-to-arm works, Library opens alongside HUD
- Every OLL/PLL/F2L diagram visually matches SpeedCubeDB/JPerm for 5 random spot checks each (list the spot checks in the final commit message)
- PROBLEMS.md: all in-progress reset to pending or moved to Solved with how-fixed
- NEXT.md + TASKS.md updated, `git log --oneline -10` shows one commit per task
- Efficiency: batch file reads, one build per task, no redundant test runs

Begin now. No questions, no progress pings. Final output only: last commit SHA + build/test line.
