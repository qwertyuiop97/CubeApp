# CubeNotch

A high-performance, lightweight, native macOS utility designed specifically for speedcubers (3x3x3 algorithms).

It functions as a **borderless, floating, semi-transparent Heads-Up Display (HUD)** that stays pinned on top of active workspaces, browsers, or web-based timers (like CSTimer). Its primary goal is to provide instantaneous, glanceable algorithm sheets, case visualizations, and setup sequences without requiring the user to switch windows, break focus, or disrupt their solve flow.

## Development

Requires Xcode 26 with its macOS SDK; deployment target is macOS 14 or later.

```sh
make build   # compile; warnings are errors
make test    # complete XCTest suite; warnings are errors
make run     # start the local executable
```

The Makefile selects the SDK paired with the active Xcode toolchain, avoiding a mismatched SDK inherited from a shell. It does not change the machine's Xcode selection.

### Current work and evidence

- [`NEXT.md`](NEXT.md): current continuation and remaining work.
- [`HANDOFF.md`](HANDOFF.md): decisions, implementation work, observed verification and historical context.
- [`PROBLEMS.md`](PROBLEMS.md): open limitations and resolved issues.
- [`DESIGN.md`](DESIGN.md): native visual direction and design constraints.

Algorithm data is protected: OLL/PLL and F2L remain in their original databases. Parser validity, model/diagram consistency, playback roundtrips and independent source verification are different checks; none alone proves every named algorithm is correct.

To render the diagram QA sheet without changing desktop preferences:

```sh
CUBEAPP_RENDER_DIR=/tmp/cubeapp-renders \
  SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" \
  swift test --filter DiagramRenderingTests
```

---

# Original Project Blueprint: macOS Speedcubing HUD Overlay

## 1. Executive Summary & Core Intent

The application is a high-performance, lightweight, native macOS utility designed specifically for speedcubers (3x3x3 algorithms). It functions as a borderless, floating, semi-transparent Heads-Up Display (HUD) that stays pinned on top of active workspaces, browsers, or web-based timers (like CSTimer). Its primary goal is to provide instantaneous, glanceable algorithm sheets, case visualizations, and setup sequences without requiring the user to switch windows, break focus, or disrupt their solve flow.

---

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

---

## 3. Core Technical Specifications

| Component | Technical Framework / API | Implementation Target |
| --- | --- | --- |
| **Window Level** | AppKit (`NSPanel` / `NSWindow`) | `.floating`, `.nonActivatingPanel` |
| **UI Framework** | SwiftUI | Canvas API, `.ultraThinMaterial` styling |
| **State Machine** | SwiftUI Combine / Observation | Proportional dynamic layout scale bindings |
| **Data Feed** | Swift Data Model | Raw string WCA algorithm database parsing |
| **Build Tooling** | Command Line Engine | `Makefile` driven automated builds |

---

## 4. Intended Runtime Behavior

When launched, the application initializes as a headless utility, preventing an aggressive app window popup. It immediately fetches the user's default configuration, anchors itself perfectly to the preferred corner screen boundary, and presents a beautiful, responsive, blurred overlay.

As the user cycles through algorithms via keyboard shortcuts or minimal menu interaction, the text updates instantly, the canvas re-draws the correct vector color positions in real time, and the panel remains a quiet, non-obtrusive, hyper-functional visual companion.

---

## Current Implementation Notes

- The four-layer architecture above is implemented.
- See `SCRATCHPAD.md` for the full verbatim copy of this blueprint plus ongoing experiments.
- `AlgorithmDatabase.swift` remains the protected single source of truth (ignore any model-related details outside the data layer).

_Last updated: 2026-06-27_
