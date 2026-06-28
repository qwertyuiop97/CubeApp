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

## RULES (always apply)
- Never modify or remove existing OLL/PLL cases in AlgorithmDatabase.swift
- Window must remain non-activating at all times except global hotkeys (CGEventTap)
- Spring animations on all show/hide transitions — no linear easing
- All new files go in the correct Sources/ subfolder per AGENTS.md directory layout
