# PROBLEMS — Active Issue Tracker

> **For all coding agents (Kilo Code, Claude Code, Grok Build):**
> Log any blocker, build error, unresolved design question, or bug here as you encounter it.
> Keep status accurate — do NOT mark something "in-progress" unless you are working on it *right now*.
> Update this file at the START and END of every work session.
> Claude Code uses this file to review issues and plan fixes across sessions.

---

## Status Legend

- `pending` — found but not yet addressed
- `in-progress` — actively being worked on this session
- `solved` — fixed, check it off

---

## Active Problems

- [x] **Independent review: Carbon hotkey error handling and event ownership**
  - **Status:** `solved`
  - **Verification:** Parent integration rerun passed all 25 hotkey tests with warnings-as-errors. Handler/API errors and event ownership now covered. Worker live Carbon experiment did not reproduce the proposed same-ID/different-combination collision; that hypothesis is not a confirmed defect.
  - **Original defect:** Handler installation and event-parameter read statuses were ignored; unrelated IDs returned handled; callback lacked automatic cleanup.
  - **Rejected hypothesis:** Same live ID with different combinations succeeded in the worker’s Carbon probe. Actual duplicate-combination failure and preserving an old binding are covered.
  - **Work:** Dedicated registrar regression/fix lane; evidence goes in `docs/HOTKEY-REVIEW.md`.

- [x] **Independent review: Settings capture may never receive keyboard focus**
  - **Status:** `solved`
  - **Evidence:** AppKit probe: `.nonactivatingPanel` has `canBecomeKey == false` and `makeKey()` is a no-op. Local monitors never see keys unless this app is dispatched events. Idle HUD stays non-key; **Change…** requests temporary key + activate; cancel/disappear/success restore. Offscreen unit: `HotkeyCaptureFocusTests` (6). Not interactive foreground capture. See `docs/HOTKEY-FOCUS-VERIFICATION.md`.
  - **Work:** Focus lifecycle investigation and regression coverage; ordinary HUD display must remain nonactivating.

- [x] **Independent review: invalid playback can display a solved cube**
  - **Status:** `solved`
  - **Verification:** Successful-load gating, presentation regressions and native error render passed in the 123-test parent run.
  - **Finding:** Clearing failed playback resets internal state to solved; rendering must not expose that reset state as a valid diagram.
  - **Work:** Playback/visual worker adding explicit unavailable state and invalid-input regression coverage.

- [x] **Independent review: bitmap blank detection ignores row stride**
  - **Status:** `solved`
  - **Verification:** Parent integration rerun passed all 10 screenshot tests. Raw padded bitmap helper regression fixed; TIFF normalization masked this in the production image path, so no user-visible capture failure is claimed.
  - **Original defect:** Alpha scan used packed offsets rather than `bytesPerRow`; helper now respects row stride.
  - **Work:** Reproduce with padded bitmap/format coverage, accounting for TIFF normalization; do not claim user-visible capture failure without evidence.

- [ ] **External algorithm identity verification is not complete**
  - **Status:** `pending`
  - **Context:** Parser validity and inverse/forward cube mechanics do not prove that an algorithm matches its named canonical case. The corrected notation audit and 17 Python regression tests were rerun by the parent; persisted result fields match the fresh computation. See `docs/ALGORITHM-VERIFICATION.md`: 54/57 OLL and 21/21 PLL have same-id/name notation candidates, not identity proofs. F2L has zero same-id matches and eight candidates elsewhere; protected numbering/content remains unresolved.
  - **Boundary:** Protected algorithm databases remain unchanged.

- [ ] **Interactive UI and system accessibility smoke checks remain incomplete**
  - **Status:** `pending`
  - **Evidence:** Native diagram renders pass at all three sizes in light/dark. The debug executable stayed running but desktop tooling did not find its window; it was terminated after the attempt.
  - **Next:** Finish native playback/detail visual review. Do not claim Reduce Motion/Transparency system testing: those environment values are read-only and no system preferences were changed.

- [ ] **Smooth intra-move animation and full F2L slot view remain future work**
  - **Status:** `pending`
  - **Evidence:** Playback advances real states at move boundaries; it is not a verified 60fps turn renderer. F2L uses a real inverse-state plan view, not a full slot visualization.

<!--
Template for a new entry — copy/paste and fill in:

- [ ] **Short title** — one-line description of the problem
  - **Discovered:** Phase 6B / 2026-06-27
  - **Status:** `pending`
  - **Context:** What triggered this? What was being built when it appeared?
  - **What was tried:** (fill in attempts made)
  - **Suspected fix:** (your best guess at a solution, or "unknown")
-->

---

## Solved Problems


- [x] **Cube diagrams disagree with engine-derived recognition states**
  - **Status:** `solved`
  - **Evidence:** Baseline diagnostics report 52 OLL U-face mismatches while tests pass because comparisons only print. Existing fallback invents colors from case numbers.
  - **Action:** Replace inaccurate pattern tables and heuristic fallback with strict-parser-backed cube states; add real assertions and playback.

- [x] **Cube parser rejects explicit wide notation and accepts malformed recognition input**
  - **Status:** `solved`
  - **Evidence:** Regression `testParserAcceptsExplicitWideMoveNotation` fails on `Rw`; tokenizer also interprets `Rw` as a single R face turn.
  - **Action:** Unify token parsing, cover whitespace and invalid recognition requests, keep protected algorithms unchanged.

- [x] **Custom hotkey persistence and failed registration can lose the binding**
  - **Status:** `solved`
  - **Evidence:** A (key code 0) is treated as missing, and raw defaults convert unchecked to UInt32. Existing binding is removed before replacement registration succeeds.
  - **Action:** Isolated persistence/registration regression tests and transactional rebinding.

- [x] **Inherited SDKROOT does not match Xcode's Swift compiler**
  - **Status:** `solved`
  - **Context:** Baseline `swift test` fails before compiling the manifest: inherited CommandLineTools macOS 27 SDK requires Swift 6.4, selected Xcode provides Swift 6.3.3 and macOS 26.5 SDK.
  - **Next check:** Use `SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"` for this project's builds; do not change global Xcode selection.

- [x] **Liquid Glass material API unknown / unconfirmed** — Phase 8A-4
  - **Discovered:** Phase 8A / 2026-06-27
  - **Status:** `solved` (historical uncertainty superseded by compiled implementation)
  - **Context:** NEXT.md requires research of "SwiftUI Liquid Glass macOS 26" and "macOS 26 glass material SwiftUI API" before any code. Only implement if a confirmed, compilable public API exists.
  - **Research performed:** Attempted web fetch of Apple SwiftUI / Material docs and background APIs. Pages require JavaScript; no concrete API names, availability, or examples returned. No official documentation for `.glass`, `.glassBackground()`, `Material.glass`, or similar surfaced.
  - **Conclusion:** API is unknown / unconfirmed in available public sources. Per NEXT.md: log here, leave material as-is (current .thinMaterial + tint overlay), do not block rest of Phase 8A.
  - **Action taken:** Skipped implementation. No code changes. Will revisit if/when confirmed API becomes available in future SDKs.
  - **Suspected fix:** Wait for official Apple docs / Xcode beta with confirmed SwiftUI glass effect API, then wrap in `#available(macOS 26, *)`.

- [x] **Integration cleanup and regression findings**
  - **Status:** `solved`
  - **Evidence:** `make build` / `make test` with warnings-as-errors passed 95 tests before the separate rendering-test addition. Wide aliases, whitespace, strict invalid input, STM, disjoint search/history, saved hotkeys, callback-preserving rebinding, actual main-loop playback, and screenshot local capture/write failures are covered.
  - **Additional fixes:** White face stickers no longer render as masked dark during playback. Screenshot capture no longer falls back to the whole display; PNG writes report success only after the write succeeds. Deprecated capture calls and unused daily-streak variable removed.
  - **Liquid Glass:** `GlassModifier.swift` compiles `.glassEffect` behind availability guards; the original API-unknown entry above is historical, not a current blocker.
  - **CI:** Xcode absence now fails instead of producing a skipped-build success.


*(move entries here — with checkmark — once resolved)*

<!--
Template for a solved entry:

- [x] **Short title**
  - **Discovered:** Phase X / date
  - **Solved:** date
  - **How:** one-line explanation of what fixed it
-->

---

## Rules for Agents

1. **Log immediately** — the moment you hit a blocker or unexpected behavior, add it here before continuing or abandoning the task.
2. **One entry per distinct problem** — don't bundle multiple issues into one entry.
3. **Status must be honest:**
   - Set `in-progress` only while actively working on that problem.
   - If you stop working on it (session ends, you move to something else), revert to `pending`.
   - If solved, move the entry to "Solved Problems" and check the box.
4. **Don't delete entries** — even if unsolved and abandoned. They may be relevant to future sessions.
5. **Don't modify AlgorithmDatabase.swift** to work around problems — fix the actual issue.
6. **Claude Code checks this file** to provide reasoning or plans for hard problems. Keep notes detailed enough that it can understand the context without reading all your code.
