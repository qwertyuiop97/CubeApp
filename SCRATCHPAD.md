# SCRATCHPAD.md — Window Anchoring Math Brainstorm

## Goal
Position the floating transparent window intelligently near the macOS menu bar / notch area without overlapping critical UI, while staying non-activating and always visible.

## Key Constraints
- Window is borderless + transparent.
- Must respect notch on MacBook Pros (especially 2021+ models).
- Should not cover menu bar items or the notch camera area.
- Must follow the user when they move between displays.
- User may want to drag it manually (`isMovableByWindowBackground`).
- Should snap back to a "preferred" anchored position on launch or when toggled.

## Current Ideas

### 1. Preferred Anchor Zones
- Top-right of main screen, just below menu bar, left of the notch if present.
- Top-center, directly below menu bar (good for notch-less Macs).
- User-configurable "dock side": left, right, center.

### 2. Notch Detection
- Use `NSScreen` + `safeAreaInsets` (macOS 12+).
- On screens with notch: `screen.safeAreaInsets.top` gives the reserved height.
- Always place window below `menuBarHeight + safeAreaInsets.top + smallPadding`.

### 3. Positioning Math Sketch
```swift
let screen = NSScreen.main!
let visibleFrame = screen.visibleFrame
let menuBarHeight = screen.frame.height - visibleFrame.height

let notchExtra = screen.safeAreaInsets.top  // 0 on non-notch screens
let topPadding = 8.0

let windowHeight: CGFloat = currentSizeMode.height
let windowWidth: CGFloat = currentSizeMode.width

let x = visibleFrame.maxX - windowWidth - 12   // right aligned with margin
let y = visibleFrame.maxY - windowHeight - topPadding

window.setFrameOrigin(NSPoint(x: x, y: y))
```

### 4. Multi-Monitor Handling
- Always default to the screen with the menu bar (`NSScreen.main`).
- Provide a preference to "follow active screen" or "stay on primary".
- When user drags the window to another screen, remember that screen for future launches.

### 5. Snap / Restore Behavior
- On app launch or toggle: animate to last known good position or preferred anchor.
- If the saved frame is now off-screen (display config changed), fall back to calculated anchor.
- Use `NSWindow.didChangeScreenNotification` to re-evaluate position.

### 6. Interaction Edge Cases
- Clicking the window should not activate other apps (use `nonactivatingPanel` style).
- Allow click-through when idle? (Optional future toggle.)
- Provide a small "grip" or title bar area for manual dragging.

### 7. Future Experiments
- Dynamic "magnet" to menu bar edge.
- Auto-hide when full-screen apps are active.
- User can double-click header to cycle through preset positions.

## Open Questions
- Should the window remember exact pixel position per display, or always use relative anchoring?
- Do we want a "compact mode" that tucks closer to the notch when user has many menu bar items?
- How do we handle stage manager / spaces?

Write concrete code experiments here as we prototype.

---

## Architectural Layout Plan: Custom Floating Window + Canvas Cube Visualizer
**DRAFT — Do not implement until explicitly approved.**

### High-Level Goals
- Deliver a lightweight, always-available floating macOS utility for speedcubing algorithms.
- Use AppKit exclusively for the window host (level, activation, collection behavior, borderless transparent style).
- Use SwiftUI + Canvas for all visuals, materials, and responsive scaling (compact/medium/large).
- Keep the entire window non-activating and movable by background.
- Cube visualizer must be crisp, vector-based, scale cleanly, and driven purely from `AlgorithmDatabase` data (never duplicate cases).

### Layered Architecture (Strict Separation)

1. **AppKit Host Layer** (owns the window)
   - Single `CubeFloatingPanel` (NSPanel subclass) or `FloatingWindowController` managing one persistent borderless transparent panel.
   - Configuration (from CLAUDE.md):
     - styleMask: [.borderless]
     - isOpaque: false
     - backgroundColor: .clear
     - level: .floating (or .statusBar for notch proximity)
     - collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
     - hasShadow: true
     - isMovableByWindowBackground = true
   - Never calls `activate(ignoringOtherApps:)` except on explicit user gesture.
   - Responsible for:
     - Creating and retaining the `NSHostingController<RootSwiftUIView>`
     - Applying size-mode frame adjustments (window resizes when user changes compact/medium/large)
     - Handling screen changes, notch-safe positioning, and anchoring logic (see existing math section)
     - Persisting/restoring last frame or preferred anchor per screen
   - Entry point: App-level coordinator (future AppDelegate or main actor service) that shows/hides/toggles the panel.

2. **SwiftUI Content Layer** (owns visuals, state, materials)
   - Root view hosted inside the NSHostingController.
   - Applies modern materials at the root: `.background(.regularMaterial)` or `.thinMaterial` with subtle overlays.
   - Receives size mode via `@AppStorage("sizeMode")` or injected observable `SizeModeSettings` model (values: .compact, .medium, .large).
   - All padding, fonts, card sizes, and visualizer scale are derived from the current size mode (no hard-coded constants).
   - Structure sketch (logical, not code):
     - Root: Material background + safe area handling for notch
     - Top bar: minimal draggable grip area + close/hide controls (if any)
     - Main content: Split or stacked layout
       - Case selector / search / filters (OLL vs PLL tabs or segmented)
       - Selected case detail: name, primary algorithm, alternatives list
       - CubeVisualizer view (the Canvas component)
     - Bottom or side: settings trigger (size mode picker)
   - Data access: Views and view models read cases only through a thin `AlgorithmService` facade. Never import or reference raw case data literals outside Core/Data.
   - State: Lightweight `@State` / `@Observable` for current selection and search text. Size mode is the only persisted UI state initially.

3. **Cube Visualizer Component** (SwiftUI Canvas)
   - Lives under UI/Components or Features/CubeDisplay.
   - Takes a `CubeCase` (or its sticker state representation) as input.
   - Renders a 2D net or isometric cube face layout using `Canvas { context, size in ... }`.
   - Responsibilities:
     - Draw 6 faces (or unfolded net) with standard Rubik’s colors (white, yellow, red, orange, blue, green).
     - Highlight the relevant stickers for the current OLL/PLL case.
     - Support orientation hints (arrows or rotation indicators) if needed for the algorithm.
     - Scale the entire drawing based on the current size mode (canvas size and stroke widths respond to compact/medium/large).
   - Must remain pure and lightweight — no heavy 3D; Canvas is chosen for crisp vector output and easy scaling.
   - Future extension point: replace internal drawing with SceneKit/ RealityKit view if 3D is later approved, without changing the host window architecture.

### Size Mode Scaling Strategy
- Enum: `SizeMode { case compact, medium, large }`
- Stored in `@AppStorage` at AppKit/SwiftUI boundary.
- On change:
  - SwiftUI root view recomputes all metrics (via environment value or computed properties).
  - AppKit window controller receives notification (or observes the same storage) and animates the window frame to new target size while preserving anchor position.
- Test at all three sizes on notched and non-notched screens.

### Data & Protection Boundaries
- `AlgorithmDatabase` (in Sources/Core/Data) remains completely untouched.
- All new code reads via a service layer or static accessors only.
- No algorithm strings or case lists ever appear in views, view models, or the visualizer.

### Window Lifecycle & Interaction
- Launch: Coordinator creates panel once, positions it using anchoring math + notch insets, shows without activation.
- Toggle (global hotkey or menu bar): show/hide or bring to front without stealing focus.
- Drag: native `isMovableByWindowBackground`.
- Resize on size mode change: controlled animation from AppKit side.
- Multi-monitor: prefer screen with menu bar; remember last screen when dragged.

### Files / Module Placement (proposed)
- Sources/App/ — AppDelegate / WindowCoordinator (AppKit)
- Sources/Core/Services/ — FloatingWindowService or SizeModeSettings (if shared)
- Sources/UI/Components/ — CubeVisualizer (Canvas), CaseCard, AlgorithmList
- Sources/UI/Views/ — MainHostedView (root SwiftUI)
- Sources/Features/CubeDisplay/ — any visualizer-specific models or extensions
- No new files under Core/Data

### Open Decisions (to resolve before coding)
- Exact initial anchor + animation when size mode changes.
- Whether the visualizer shows full cube net or just the affected faces for OLL/PLL.
- How algorithm text is presented (copy button? fingertrick grouping?).
- Minimum macOS target (must support safeAreaInsets + modern materials → Sonoma+ recommended).
- Should Canvas draw use a dedicated `CubeState` struct (derived from case) or pass raw case data?

### Next Steps (after approval)
1. Add Package.swift (SPM) or .xcodeproj so `make build` works.
2. Implement AppKit host first (borderless panel + hosting controller skeleton).
3. Add size mode model + persistence.
4. Build the Canvas visualizer as an isolated, testable component.
5. Wire selection list + detail view.
6. Integrate anchoring math from top of this file.

**Status: IMPLEMENTED** — Core blueprint (borderless floating AppKit window, @Observable state, Canvas visualizer in 3 modes, ultraThinMaterial UI, 4-corner anchoring) has been fully built and compiles cleanly. The detailed "Project Blueprint" section below is now the authoritative reference.

---

## User's Full Project Blueprint (Authoritative Reference)

This is the complete, high-fidelity architectural and feature specification provided by the user. It supersedes earlier drafts.

# Project Blueprint: macOS Speedcubing HUD Overlay

## 1. Executive Summary & Core Intent

The application is a high-performance, lightweight, native macOS utility designed specifically for speedcubers (3x3x3 algorithms). It functions as a borderless, floating, semi-transparent Heads-Up Display (HUD) that stays pinned on top of active workspaces, browsers, or web-based timers (like CSTimer). Its primary goal is to provide instantaneous, glanceable algorithm sheets, case visualizations, and setup sequences without requiring the user to switch windows, break focus, or disrupt their solve flow.

## 2. Architectural Design & System Components

The application is structured into four highly decoupled, specialized architectural layers to ensure performance, state consistency, and rapid UI scaling:

### A. Core Window Engine (`FloatingOverlayWindow.swift`)

Built entirely on low-level **AppKit (`NSWindow`)** rather than standard SwiftUI window structures to allow deep control over macOS window server traits.

* **Always-on-Top Level:** The window level is set explicitly to `.floating` or `.statusBar`, ensuring it stays visible above full-screen web apps or local tools.
* **Non-Activating Panel:** Configured as an `NSPanel` with the `.nonActivatingPanel` collection behavior. This ensures that clicking the overlay or adjusting its settings **never steals keyboard focus** from the user’s background timer or active app.
* **Zero-Chrome Transparency:** The window has a completely borderless style mask (`.borderless`), a completely transparent background (`.clear`), and suppresses standard macOS window controls (minimize, maximize, close frames).
* **Corner-Anchoring Metrics:** Reads screen constraints natively using `NSScreen.main`. It includes a programmatic alignment function that subtracts the native macOS Menu Bar height and dynamically calculates exact pixel positions to snap the window cleanly into one of four corners: Top-Left, Top-Right, Bottom-Left, or Bottom-Right.

### B. State Management & Core Logic (`CubeStateManager.swift`)

A centralized state machine utilizing modern observation paradigms (`@Observable` or `ObservableObject`) to serve as the unified source of truth.

* **Active Case Tracking:** Reads, filters, and loads active OLL (Orientation of the Last Layer) or PLL (Permutation of the Last Layer) cases directly from `AlgorithmDatabase.swift`.
* **Layout Scaling States:** Dictates a multi-tier size state (`.compact`, `.medium`, `.large`) that scales every visual aspect of the application uniformly using proportional scaling factors.
* **Algorithm Parsing:** Houses a sequence text parser that ingests standard World Cube Association (WCA) notation (e.g., `R U R' U' F'`). It converts these strings into active instruction sequences for the renderer.

### C. Interactive Cube Visualizer (`CubeStateView.swift`)

A highly optimized visualizer built using a native **SwiftUI `Canvas`** layer or custom vector `Shape` paths rather than heavy 3D assets to keep CPU and memory overhead near 0%.

* **Sticker Representation:** Renders a clean 2D top-down (or stylized isometric oblique projection) 3x3 grid layer representing the last layer of a Rubik's cube, surrounded by outer edge indicators.
* **Mode 1: Pre-Execution State (Recognition Mode):** Paints the grid layout showing the exact sticker orientation the user needs to recognize on their physical cube right before executing the active algorithm.
* **Mode 2: Setup State (Inversion Mode):** Programmatically inverts the algorithm sequence to show the cube state required to *generate* that specific case from a solved state, allowing for rapid, hands-on muscle memory practice.
* **Mode 3: Hide Visuals (Minimalist Mode):** Collapses the graphical Canvas entirely with a clean transition, reducing the interface to a single text string line for experienced cubers who only need quick text lookups.

### D. User Interface Assembly (`MainOverlayViews.swift`)

The visual presentation envelope assembled in SwiftUI, balancing premium aesthetic design with raw scannability.

* **Visual Aesthetic:** Wrapped completely in a native macOS frosted-glass system effect (`.ultraThinMaterial`) with thin, elegant borders, making it blend seamlessly into the modern macOS desktop environment.
* **Dynamic Type & Scale Responsiveness:** Font hierarchies, padding constraints, frame limits, and vector drawing calculations are completely bound to the global scale state.
* **Heads-Up Control Overlay:** An expandable, slide-out, or popover configuration panel that exposes clean dropdown menus/toggles for layout scale adjustments, viewport orientation changes, and corner-snap positions without cluttering the screen.

## 3. Core Technical Specifications

| Component | Technical Framework / API | Implementation Target |
| --- | --- | --- |
| **Window Level** | AppKit (`NSPanel` / `NSWindow`) | `.floating`, `.nonActivatingPanel` |
| **UI Framework** | SwiftUI | Canvas API, `.ultraThinMaterial` styling |
| **State Machine** | SwiftUI Combine / Observation | Proportional dynamic layout scale bindings |
| **Data Feed** | Swift Data Model | Raw string WCA algorithm database parsing |
| **Build Tooling** | Command Line Engine | `Makefile` driven automated builds |

## 4. Intended Runtime Behavior

When launched, the application initializes as a headless utility, preventing an aggressive app window popup. It immediately fetches the user's default configuration, anchors itself perfectly to the preferred corner screen boundary, and presents a beautiful, responsive, blurred overlay.

As the user cycles through algorithms via keyboard shortcuts or minimal menu interaction, the text updates instantly, the canvas re-draws the correct vector color positions in real time, and the panel remains a quiet, non-obtrusive, hyper-functional visual companion.

---

**Note to future agents:** This entire blueprint section is the user's direct specification. Preserve it verbatim in SCRATCHPAD.md / README.md. Implementation must stay faithful to the four-layer separation and the exact behaviors described.

---

## Canonical Feature Checklist (User-Authored, 2026-06-27)

> This is the authoritative non-technical feature spec. Build order and priorities in TASKS.md derive from this.

**Always-on-Top Floating HUD:** Borderless, clean HUD pinned over browser/CSTimer. No window-swapping.

**Zero-Click Focus (Click-Through Behavior):** Clicking the overlay never steals keyboard focus. Timer spacebar always works.

**One-Click Corner Anchoring:** Snaps to Top-Left, Top-Right, Bottom-Left, Bottom-Right with zero manual dragging.

**Dynamic Multi-Size Scaling:** Compact / Medium / Large — fonts, buttons, and graphics all scale proportionally.

**Premium Modern Aesthetic:** Native macOS frosted-glass (`.ultraThinMaterial`) that blends with modern desktop.

**Integrated Algorithm Sheet:** Built-in connection to the OLL/PLL library, cycle through cases instantly.

**3-Mode Visualizer Engine (native SwiftUI Canvas):**
1. Pre-Execution State — exact sticker placement to recognize on physical cube before executing
2. Setup State — inverts algorithm steps, shows scramble text + inverted sticker state on Canvas
3. Hide Visuals — collapses Canvas to minimalist text-only strip

### Workflow
1. App launches quietly → borderless frosted-glass panel fades into chosen corner
2. Pick OLL or PLL case → WCA notation populates in panel
3. Roofpig 3D cube appears → click play to watch animation, mouse over to spin and inspect sides
4. Expand settings tray → toggle Setup State, change size mode, snap to different corner
5. Close tray → overlay rests silently as reference while user solves

