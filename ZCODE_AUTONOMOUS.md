# CubeApp — Resume Prompt v2 (Z Code, no interruptions)

Run in ~/Projects/CubeApp until DONE. Do not ask questions. Do not stop between items. Only stop when `swift build` is clean, `swift test` passes, and every item below is complete. If blocked on one item, log it in PROBLEMS.md as pending and continue to the next independent item.

## 0. Startup (read once)
1. `git status --short`, `git log --oneline -5`
2. Read NEXT.md Phase 13A (lines ~281-317), HANDOFF.md Tasks 1-5, AGENTS.md, CLAUDE.md
3. Protected: AlgorithmDatabase.swift (57 OLL + 21 PLL) + F2LDatabase.swift (41 cases) — verify counts, never invent data. ContentView lives in Sources/UI/MainOverlayViews.swift.

## 1. Phase 13A — the only NOT STARTED phase (do this first)
- 13A-1 Move counts: `moveCount()` helper, "X moves" next to every alg in HUD + Library.
- 13A-2 AUF for PLL: optional `auf` on CubeCase, shown in Library PLL detail.
- 13A-3 Recognition tips: optional `recognitionTip` on CubeCase, all 21 PLL + common OLLs ("headlights", "sune", etc.), italics in HUD, section in Library.
- 13A-4 Hotkey customizer: Settings row, tap-to-record, persist combo, guard against Space/Escape/Return alone.
- 13A-5 Pinned/Recent: Recent-5 section, pin via secondary click, persisted.
- After each sub-item: `swift build` clean. One commit per sub-item.

## 2. Algorithm integrity (past model hallucinated algs — never again)
- Cross-check every primary alg against 2+ of SpeedCubeDB / JPerm / AlgDb / CubeSkills via web fetch. Valid notation only (U D R L F B + ' 2, wide r Rw, x y z, M E S).
- On mismatch: leave data as-is, log caseID + current + sources in PROBLEMS.md, continue.
- Extend Tests/: counts (57/21/41), ≥2 alts each, parser-valid tokens. `swift test` all pass.
- Commit: "Verify algorithm databases against public sources + tests"

## 3. Cube visuals + playback animation (must be pro, not basic)
- StickerDatabase.swift with real per-case patterns (HANDOFF Task 5 Part B spec). Rewrite drawLastLayer() to cross plan view (B top, L/U/R middle, F bottom, 3x1 strips). Correct yellows/dims, PLL side colors, sticker radii + gaps, scales compact/medium/large.
- New AlgorithmAnimator.swift: move-by-move playback from a real cube model (never hand-tweened colors), Play/Pause/Step/Reset, 0.5x–3x speed, trigger highlight, progress bar. Wire into HUD detail + Library detail. 60fps, respects Reduce Motion.
- Commit per piece. Spot-check 5 random cases per set against SpeedCubeDB/JPerm, list checks in commit message.

## 4. Done = build clean, tests pass, NEXT.md Phase 13A marked DONE, PROBLEMS.md honest, one commit per item.
Final output only: last SHA + build/test line.
