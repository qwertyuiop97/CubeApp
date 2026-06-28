# IDEAS — Unfiltered Concepts & Future Directions

> This file captures raw ideas before they're ready to become tasks. Nothing here is committed to — it's a thinking space. Move ideas to TASKS.md or a new project when they're ready to build.

---

## iOS App Concept: "Learn to Solve" (Separate Project)

**Core Idea:** A structured, daily-lesson iOS app that teaches anyone to solve a Rubik's cube — no prior knowledge needed. Think Duolingo for cubing.

**Target Audience:**
- Absolute beginners (bought a cube, don't know where to start)
- All ages: kids, teenagers, adults
- People who searched "how to solve a Rubik's cube" on YouTube/Google
- NOT targeting existing speedcubers (that's the Mac app's audience)

**Daily Learning Format:**
- 1–2 lessons per day, short and digestible
- Each lesson teaches one concept or move set
- Built-in review of past lessons (spaced repetition style)
- By the end (30 days or less) the user can solve the cube

**Progression:**
1. Beginner's Layer-by-Layer method (white cross → F2L → OLL → PLL in simplified form)
2. Optional upgrade path: "Ready for more? Learn CFOP"
3. Algorithm reference unlocked as you progress

**Dual-Purpose Angle (the insight):**
- Beginners use it to learn
- Once they can solve, they stay for the algorithm reference (F2L from every angle, cross tricks, multiple alg options per case)
- This is the gap: existing apps either teach OR reference, never both
- Most cubing apps are trash — algorithm lists with no context, no alternatives, no cross tips

**Monetization:** Free with ads. Possible IAP to remove ads or unlock advanced content (CFOP deep dive, advanced subsets).

**What makes it different from what exists:**
- Every existing "learn to cube" app shows a list of algorithms — no guidance, no structure
- No existing app has F2L from every angle with multiple options
- No app has cross tricks/algorithms (specific moves good for cross efficiency)
- None combine structured daily learning + full algorithm reference

**Open Questions:**
- Does this become a companion to the Mac app (same brand) or fully separate?
- iOS only or also Android?
- How do App Store "learn to solve" apps perform? (→ add to research queue)

---

## Mac App Aesthetic Direction

**Goal:** The app should look genuinely beautiful — not just "dark mode with blur." Modern, slick, premium feel.

**Key aesthetic ideas:**
- **Liquid Glass** — user is on macOS 27 beta. If Liquid Glass APIs are available in SwiftUI, use them. The overlay should feel like a physical glass panel floating on the desktop.
- **Variable blur** — user should be able to control how blurry/transparent the background is (slider in settings)
- **Background tint options** — let user pick a subtle tint color for the overlay (neutral/dark/light/accent color)
- **The scramble display** — show the scramble algorithm in a clean, readable way. Consider showing a mini cube diagram alongside it.
- **Everything should feel like it belongs on macOS** — use system materials, system fonts, SF Symbols throughout

**Liquid Glass notes:**
- macOS 26/27 introduces new material APIs — research what's available in SwiftUI on the beta
- Liquid Glass is Apple's new design language; using it makes the app feel cutting-edge
- Fallback: `.ultraThinMaterial` for older macOS versions, Liquid Glass for 26+
- Add a minimum deployment target decision: macOS 26 only (Liquid Glass) vs macOS 14+ (wider reach)

---

## Combined App Vision (Mac + iOS, Same Brand)

The Mac app and iOS app could share a brand and complement each other:
- **Mac app (CubeNotch):** HUD overlay for active solvers, algorithm reference library, timer
- **iOS app:** Learn to solve + algorithm reference + timer for on-the-go practice
- Same algorithm database, same brand identity
- iOS app feeds users into the Mac app as they get more serious

---

## Other Random Ideas (Capture, Don't Commit)

- Community algorithm contributions (user-submitted alts, upvote system)
- iCloud sync between Mac and iOS apps
- Competition prep mode: given a WCA scramble, show predicted OLL/PLL case
- "Trainer" mode: random case flashcards, user says the alg from memory, app reveals correct answer
- Finger trick annotations on algorithms (R=right ring, U=left index, etc.)
