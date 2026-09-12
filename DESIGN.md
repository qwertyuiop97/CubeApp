# CubeNotch Design Reference — macOS 2026

This document captures research-backed design decisions for CubeNotch, a floating speedcubing HUD
built with SwiftUI + AppKit on macOS Tahoe 26. It is meant to be actionable: every
recommendation includes either a code pattern or a specific rationale drawn from how top
Mac apps are built and reviewed in 2026.

---

## 1. Liquid Glass — What It Is and How to Use It

### What Apple Shipped in macOS Tahoe 26

Liquid Glass is Apple's biggest design shift since iOS 7. It is not just a blur effect — it is
a dynamic material that *lenses* light (bends and concentrates it, unlike the scattering of
`ultraThinMaterial`) and adds specular highlights, adaptive shadows, and reactive motion.

It ships across iOS 26, iPadOS 26, macOS Tahoe 26, watchOS 26, tvOS 26, and visionOS 26.

On macOS, it governs toolbars, sidebars, the menu bar (now fully transparent), and window chrome.
The sidebar ambient reflection feature requires no developer configuration — sidebars automatically
pick up light from nearby colorful content.

### The Golden Rule

> Liquid Glass belongs in the *navigation/functional layer* that floats above content. Never in
> the content layer itself.

Apply it to: toolbars, floating controls, HUD overlays, transient panels, navigation bars.
Do not apply it to: card content, scrollable lists, backgrounds, full-screen fills.

### Confirmed SwiftUI API (macOS Tahoe 26 / iOS 26)

```swift
// Basic — defaults to .regular variant in a Capsule shape
.glassEffect()

// With explicit variant and shape
.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

// With semantic tint (use for primary actions only)
.glassEffect(.regular.tint(.blue.opacity(0.6)))

// Clear variant — for controls over photos or maps (high transparency)
.glassEffect(.clear, in: RoundedRectangle(cornerRadius: 12))

// Coordinating multiple glass elements (required when they are close together)
GlassEffectContainer(spacing: 40.0) {
    Button("Scramble") { }.glassEffect()
    Button("Settings") { }.glassEffect()
}

// Morphing between states with glassEffectID
@Namespace private var ns
Button(isExpanded ? "Collapse" : "Expand") { withAnimation(.bouncy) { isExpanded.toggle() } }
    .glassEffect()
    .glassEffectID("toggle", in: ns)

// Button styles
.buttonStyle(.glass)           // Secondary actions — translucent
.buttonStyle(.glassProminent)  // Primary actions — more opaque
```

### Glass Variants

| Variant      | Transparency | Adaptivity | Best For                        |
|-------------|-------------|------------|---------------------------------|
| `.regular`  | Medium      | Full       | Toolbars, most controls, HUDs   |
| `.clear`    | High        | Limited    | Controls over image backgrounds |
| `.identity` | None        | N/A        | Conditionally disabling glass   |

### AppKit: NSGlassEffectView

For AppKit-hosted code paths:

```swift
// In Swift/Objective-C AppKit
let glassView = NSGlassEffectView(frame: someRect)
glassView.cornerRadius = 16
glassView.tintColor = NSColor.systemBlue.withAlphaComponent(0.3)
// glassView.style = .regular or .clear
parentView.addSubview(glassView)
// Set glassView.contentView to your actual content view
```

For grouping (same as GlassEffectContainer in SwiftUI):
Use `NSGlassEffectContainerView` when multiple `NSGlassEffectView` instances are close together.

### Critical Don'ts

- Never stack glass on glass — use `GlassEffectContainer` instead
- Do not mix `.regular` and `.clear` in the same surface
- Do not tint secondary actions — tinting is for primary emphasis only
- Remove any `NSVisualEffectView` from legacy sidebar code; it will block the new glass material
- Do not apply `.glassEffect()` to a list row, card content body, or scrollable background

### Backward Compatibility (for macOS < 26 support)

```swift
extension View {
    @ViewBuilder
    func adaptiveGlass(in shape: some Shape = Capsule()) -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(shape.fill(.ultraThinMaterial))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
    }
}
```

### Accessibility Compliance (Required)

**SDK verification note (2026-09-11):** `accessibilityReduceMotion` and `accessibilityReduceTransparency` are read-only environment values in the selected Xcode 26.5 SDK. The historical `.environment(..., true)` preview examples below do not compile and are illustrative only, not test recipes. Read those values in production; exercise policy logic through an explicit test seam, or perform a documented manual run with the user's chosen system settings. Light/dark rendering tests are not accessibility-setting tests.

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
@Environment(\.accessibilityReduceMotion) var reduceMotion

// Disable glass when user requests reduced transparency
.glassEffect(reduceTransparency ? .identity : .regular)

// Preview both states during development
#Preview("Reduce Transparency") {
    CubeNotchPanel()
        .environment(\.accessibilityReduceTransparency, true)
}
```

---

## 2. Floating Window Architecture

### The Correct Primitive: NSPanel

SwiftUI does not expose non-activating floating behavior natively. The correct AppKit type is
`NSPanel`, not `NSWindow`. The panel must be configured to never steal focus from the user's
current app.

```swift
final class CubeNotchPanel: NSPanel {
    init(rootView: some View) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 480),
            styleMask: [
                .nonactivatingPanel,
                .borderless,
                .fullSizeContentView
            ],
            backing: .buffered,
            defer: false
        )

        // Window appearance
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true

        // Floating behavior
        level = .floating          // Use .statusBar if you want notch proximity
        becomesKeyOnlyIfNeeded = true
        hidesOnDeactivate = false

        // Space behavior
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary
        ]

        // SwiftUI content
        contentView = NSHostingView(rootView: rootView)
    }
}
```

### Window Level Guide

| Level           | Value | When to Use                              |
|-----------------|-------|------------------------------------------|
| `.floating`     | 3     | Default for utility panels               |
| `.statusBar`    | 25    | Notch proximity, menu bar coexistence    |
| `.popUpMenu`    | 101   | Only when you need to appear above menus |

For CubeNotch, `.floating` is appropriate for the main panel. Use `.statusBar` only if you
implement a notch-area anchor point.

### Critical: Never Do This

```swift
// BAD — this steals focus and disrupts the user's workflow
NSApplication.shared.activate(ignoringOtherApps: true)
```

### Dismiss on Outside Click

```swift
private var clickMonitor: Any?

func showPanel() {
    panel.orderFrontRegardless()
    clickMonitor = NSEvent.addGlobalMonitorForEvents(
        matching: [.leftMouseDown, .rightMouseDown]
    ) { [weak self] _ in
        self?.dismiss()
    }
}

func dismiss() {
    panel.orderOut(nil)
    if let m = clickMonitor { NSEvent.removeMonitor(m); clickMonitor = nil }
}
```

### Persist Panel Position

```swift
NotificationCenter.default.addObserver(
    forName: NSWindow.didEndLiveResizeNotification,
    object: panel, queue: .main
) { _ in
    UserDefaults.standard.set(
        NSStringFromRect(panel.frame),
        forKey: "cubeNotchPanelFrame"
    )
}
```

On restore, validate against current screen geometry before applying the saved frame to
prevent the window appearing off-screen on display configuration changes.

---

## 3. Typography for a Speedcubing HUD

### The Timer Display

The timer is the hero element. Use the system font with monospaced digits to prevent layout
jitter as digits change each millisecond.

```swift
// Prevents width-jumping as digits change
Text(timerString)
    .font(.system(size: 72, weight: .light, design: .default))
    .monospacedDigit()
    .contentTransition(.numericText())   // Smooth cross-fade on digit change
    .foregroundStyle(.primary)

// For scramble text — monospaced is appropriate here
Text(scramble)
    .font(.system(size: 13, weight: .medium, design: .monospaced))
    .foregroundStyle(.secondary)
```

The `.contentTransition(.numericText())` modifier cross-fades digits as they update, which
reads as smooth and polished rather than jarring. Pair it with an animation:

```swift
withAnimation(.easeInOut(duration: 0.08)) {
    timerString = formatted(time: elapsed)
}
```

### SF Pro Rounded for Display Labels

For headings and category labels (OLL/PLL group names, case numbers), SF Pro Rounded reads
as warmer and more approachable than default SF Pro — appropriate for a training tool:

```swift
Text("OLL 21")
    .font(.system(size: 17, weight: .semibold, design: .rounded))

Text("T Shape")
    .font(.system(size: 13, weight: .regular, design: .rounded))
    .foregroundStyle(.secondary)
```

### Typography Scale for CubeNotch

| Role                  | Size  | Weight     | Design      | Usage                      |
|-----------------------|-------|------------|-------------|----------------------------|
| Timer display         | 72pt  | .light     | .default    | Main countdown             |
| Ao5 / Ao12 stats      | 20pt  | .regular   | .default    | Live average below timer   |
| Algorithm moves       | 15pt  | .medium    | .monospaced | R U R' U' notation         |
| Case label (OLL 21)   | 17pt  | .semibold  | .rounded    | Case heading               |
| Category / group      | 13pt  | .regular   | .rounded    | "T Shape", "Dot Case"      |
| Footnote / metadata   | 11pt  | .regular   | .default    | Move count, ETM/STM        |

Use `.monospacedDigit()` on the timer and all stat displays.

### Fixed-Width Digit Cells for Glass Timer (Advanced)

If you render the timer using Liquid Glass on each digit (like the Return app pattern from
the research), fixed-width cells prevent layout jitter at the glass layer:

```swift
HStack(spacing: 0) {
    ForEach(Array(timerString.enumerated()), id: \.offset) { _, char in
        let isColon = char == ":"
        Text(String(char))
            .font(.system(size: 72, weight: .light))
            .monospacedDigit()
            .frame(width: isColon ? 24 : 44, height: 88)
    }
}
```

---

## 4. Color and Visual Identity

### Semantic Color Approach

Never hard-code hex values. Use semantic system colors — they adapt automatically to light
mode, dark mode, increased contrast, and macOS Tahoe's Liquid Glass rendering pipeline.

```swift
// Backgrounds (resolved to appropriate glass-friendly values automatically)
Color.primary           // Labels, main text
Color.secondary         // Supporting text, metadata
Color(nsColor: .windowBackgroundColor)   // Fallback panel background

// Accent — pick one and stay consistent
Color.accentColor       // Respects user's system accent color choice

// For Liquid Glass tinting
.glassEffect(.regular.tint(Color.accentColor.opacity(0.5)))
```

### Recommended Palette for CubeNotch

CubeNotch is a dark-primary HUD. Research shows 70% of top 2026 Mac apps default to dark
backgrounds, and a single vibrant accent against dark reads as premium.

| Token             | Semantic Color            | Role                                          |
|-------------------|---------------------------|-----------------------------------------------|
| Surface           | `.ultraThinMaterial`      | Panel background (pre-26 fallback)            |
| Glass             | `.glassEffect(.regular)`  | Controls, toolbar (macOS 26+)                 |
| Primary text      | `.primary`                | Timer, algorithm moves, case name             |
| Secondary text    | `.secondary`              | Stats, footnotes, metadata                    |
| Accent — timing   | `.green` (system)         | Timer "ready" state (universal recognition)   |
| Accent — warning  | `.orange` (system)        | Inspection countdown (<5 seconds)             |
| Accent — brand    | User-chosen via Settings  | Highlights, active case indicator             |
| Divider           | `.separator`              | Between algorithm and stats                   |

### Background Tint Modes (Per CLAUDE.md requirement)

Expose four tint modes in Settings that adjust the glass/material tint:

```swift
enum BackgroundTint: String, CaseIterable, Identifiable {
    case neutral, dark, light, accent
    var id: String { rawValue }
}

// Applied as:
@AppStorage("backgroundTint") var backgroundTint: BackgroundTint = .neutral

var panelTint: Color {
    switch backgroundTint {
    case .neutral: return .clear
    case .dark:    return Color.black.opacity(0.3)
    case .light:   return Color.white.opacity(0.15)
    case .accent:  return Color.accentColor.opacity(0.2)
    }
}

// Then:
.glassEffect(.regular.tint(panelTint))
// Or for pre-26:
.background(.ultraThinMaterial).overlay(panelTint)
```

---

## 5. Layout, Spacing, and Corner Radius

### The 8pt Grid

All spacing in CubeNotch should be multiples of 8pt (4pt for tight internal spacing):

```swift
// Padding
.padding(8)     // Tight — within a compact card
.padding(16)    // Default — between sections
.padding(24)    // Loose — outer panel insets
.padding(32)    // Section breaks in large mode

// Spacing in stacks
VStack(spacing: 8) { ... }   // Related items
VStack(spacing: 16) { ... }  // Distinct sections
VStack(spacing: 24) { ... }  // Major groupings
```

### Corner Radius

macOS Tahoe increased corner radii significantly. Windows without toolbars use a moderate
radius; those with toolbars get a larger "exaggerated" radius (approximately 20-24pt for
window corners). Match this in your content:

```swift
// Panel inner content cards
.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

// Smaller controls / buttons
.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

// Pill-shaped action buttons
.clipShape(Capsule())

// Use .containerConcentric for nested elements that should match their parent:
RoundedRectangle(cornerRadius: .containerConcentric, style: .continuous)
```

Always use `style: .continuous` (superellipse). Apple's own controls use it throughout.

### Algorithm Card Layout

Each OLL/PLL card should follow this hierarchy:

```
┌─────────────────────────────────────┐
│ [Cube diagram]    OLL 21            │  ← 17pt semibold rounded
│                   T Shape           │  ← 13pt regular secondary
│                                     │
│ R U R' U' R U2 R'                  │  ← 15pt medium monospaced
│ ────────────────────────────────    │  ← .separator
│ Alt: F R U R' U' F'                │  ← 13pt regular monospaced secondary
└─────────────────────────────────────┘
```

Compact mode: collapse the alt algorithm by default.
Medium mode: show primary + 1 alt.
Large mode: show primary + 2 alts + move count.

---

## 6. Top 5 Design Decisions That Make CubeNotch Feel Premium

### Decision 1 — Glass the Controls, Not the Content

The timer display, algorithm notation, and scramble text are *content*. They must be readable
against any background without glass treatment. The *controls* (next scramble button, settings
gear, size toggle) belong in a glass toolbar strip.

```swift
VStack(spacing: 0) {
    // CONTENT — no glass
    TimerView()
    ScrambleView()
    AlgorithmCard()

    Divider().padding(.horizontal, 16)

    // CONTROLS — glass
    HStack {
        Button("New Scramble", systemImage: "shuffle") { ... }
        Spacer()
        Button("Settings", systemImage: "gearshape") { ... }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))
}
```

### Decision 2 — Monospaced Digits with numericText Transition

Without `.monospacedDigit()`, the timer jitters left and right as wide (0, 8) and narrow (1)
digits alternate. This reads as unpolished and distracting. With `.contentTransition(.numericText())`,
the cross-fade reads as a proper timer, not a label being replaced.

This single modifier has the highest polish-per-line-of-code ratio of any SwiftUI API available.

### Decision 3 — Non-Activating Panel With Drag-to-Reposition

Users hate HUDs that grab focus mid-solve. The `becomesKeyOnlyIfNeeded = true` + `.nonactivatingPanel`
combination means clicking a button in CubeNotch does not take focus from the user's active app.
`isMovableByWindowBackground = true` lets the user reposition the panel by dragging anywhere on
it — no title bar required.

Research on notch apps confirms that overlays which demand interaction on their own terms
(grab focus, show a menu, require precise targeting) are uninstalled within two weeks.
Overlays that stay passive and respond to incidental glances are kept for months.

### Decision 4 — Single Accent, Semantic Green/Orange for Timer States

Rather than a colorful brand identity, CubeNotch should use one user-selectable accent color
throughout, with two reserved semantic colors for timer state:

- Green: timer is armed and ready (universally recognized)
- Orange: inspection countdown under 5 seconds (urgency without alarm)

This approach mirrors how Lungo, One Switch, and Silenz operate — they feel *native* because
they defer to the system color language rather than imposing their own.

### Decision 5 — Blur Intensity Slider as a First-Class Setting

Different users have different backgrounds. A user with a bright white wallpaper needs a
more opaque overlay than one with a dark photograph. Expose blur intensity (which maps to
material thickness) as a slider in Settings, with a live preview. This single control
replaces dozens of app-specific complaints about "too transparent" or "too dark."

```swift
@AppStorage("blurIntensity") var blurIntensity: Double = 0.5

// Map the slider to a tint opacity
var blurTintOpacity: Double { (1.0 - blurIntensity) * 0.4 }

// Then apply as an overlay on top of the material
.background(.ultraThinMaterial)
.overlay(Color.black.opacity(blurTintOpacity))
// Or on macOS 26+:
.glassEffect(.regular.tint(Color.black.opacity(blurTintOpacity)))
```

---

## 7. What to Avoid — Common Mistakes That Get 1-2 Star Reviews

### Do Not Steal Application Focus

Any call to `NSApplication.shared.activate(ignoringOtherApps: true)` when the panel
appears will interrupt the user's timer, cursor position, or typing. This is the most
common 1-star complaint for floating overlay apps.

### Do Not Build a Custom Visual Hierarchy That Fights macOS

"Spaceship dashboard" aesthetics (custom scrollbars, glowing borders, bespoke sliders)
actively reduce trust. Research on macOS utility apps in 2026 shows that when the UI looks
custom and aggressive, users feel "pushed to buy" or "scared about their Mac" rather than
"helped." The product that looks like it belongs natively on macOS converts and retains
better than the flashier one.

Specific things that signal "this is not a real Mac app":
- Custom scrollbars
- Hover states that do not match macOS norms (no cursor change to pointer on non-links)
- Flickering between view states (the Raycast team specifically listed this as a tell)
- Animations that play on every appearance (not just the first)
- Solid dark backgrounds instead of materials

### Do Not Use Glass on Lists or Card Content

The Apple guideline is explicit: glass artifacts appear when you apply glass over glass,
and lists that scroll under a glass bar will produce unexpected rendering. Keep the
algorithm card background as a plain material or solid dark color; put glass only on
the controls above or below.

### Do Not Hard-Code Font Sizes Without Supporting Dynamic Type

On macOS, users can scale system text. If you hard-code `size: 17` everywhere without
supporting the accessibility scale, power users with visual needs will give your app 1 star.
Use `.font(.body)`, `.font(.headline)`, etc. where possible; use fixed sizes only for the
timer display where proportional behavior is genuinely undesirable.

### Do Not Launch Without Testing Reduce Transparency

File: `#Preview("Reduce Transparency") { ... .environment(\.accessibilityReduceTransparency, true) }`

Test this before every release. When Reduce Transparency is on, all glass must fall back to
a solid, legible alternative. If the app becomes unusable, you have violated a macOS
accessibility contract.

### Do Not Play Animations on Every App Appearance

Raycast's engineering team explicitly documented that "animations that flicker on transition"
are the most common signal that an app is not truly native. The glass reveal, the panel slide-in:
play them once per user-triggered show, not on every workspace switch or app re-activation.

---

## 8. Notch-Area Design

### What Works

Research on 2026 notch apps (Brow, NotchNook, Boring Notch) shows a consistent pattern:
apps that make the notch *passive* survive. Apps that require the user to deliberately
hover to expand something into the notch area are abandoned within two weeks.

If CubeNotch anchors near the notch:
- Display the current timer state (running/stopped/ready) as a small persistent indicator
- Auto-update with ambient information (current Ao5) without requiring interaction
- Keep the notch element small and non-expanding by default; expansion should be optional

### Window Positioning for Notch Proximity

```swift
// Position the panel near the notch on the main display
func positionNearNotch(panel: NSPanel) {
    guard let screen = NSScreen.main else { return }
    let visibleFrame = screen.visibleFrame
    let panelWidth: CGFloat = 320
    let panelHeight: CGFloat = 480
    let notchX = screen.frame.width / 2 - panelWidth / 2
    let notchY = screen.frame.maxY - panelHeight - 8  // 8pt below menu bar

    panel.setFrameOrigin(NSPoint(x: notchX, y: notchY))
    panel.level = .statusBar  // Appear alongside menu bar items
}
```

### What Looks Bad in the Notch Area

- Expanding popouts that cover the menu bar — users find this disorienting
- Visual effects that spill into the camera area (camera cutout = physical notch)
- Bright or colorful glow effects around the notch (Notchmeister is popular but niche;
  most users uninstall novelty effects quickly)

---

## 9. Apps Doing It Right and Why

### Raycast — The Floating Panel Gold Standard

Raycast's floating launcher is the benchmark for non-intrusive overlay panels:
- Does not steal focus (uses `.nonactivatingPanel` equivalent)
- Adopted Liquid Glass immediately on macOS Tahoe — blends rather than stands out
- Eliminated hover highlighting inconsistent with macOS norms
- Prevented any flickering during view transitions (tested with WebKit rendering sync)
- Philosophy: "We're not a web app with native hooks. We're a native app."

**Lesson for CubeNotch**: Every rendering decision should favor authentic desktop behavior.
No hover highlights that don't match system norms. No startup flash. No focus stealing.

### Tide Guide — 2026 Apple Design Award Winner (Visuals & Graphics)

Won the Design Award for its use of Liquid Glass alongside full-screen charts and dynamic
color palettes that adapt to sky color. Key pattern: the glass does not compete with the
data visualization — it *frames* it.

**Lesson for CubeNotch**: The cube diagram and algorithm notation are the data. Glass frames
the controls around them; it does not decorate the notation itself.

### Lungo by Sindre Sorhus — Minimal, Trustworthy, Native

Lungo prevents Mac sleep with a single icon in the menu bar. It is described consistently
as having "an exquisite blend of functionality, usability, and aesthetic appeal." It does
one thing. Its design does not explain itself. It feels like it shipped with macOS.

**Lesson for CubeNotch**: The core experience — see an algorithm, read it, use it — should
require zero learning. Every design decision that adds visual weight should earn it.

### Floaty — Purpose-Built Floating Overlay

The leading always-on-top tool in 2026 succeeds because: opacity slider is the first
control users reach; per-window indicators make pinned state obvious; onboarding is
frictionless. It treats "staying visible without demanding attention" as the product.

**Lesson for CubeNotch**: The opacity/blur slider is not a power-user feature — it is
a first-class control because different use contexts demand different visibility levels.

### SpeedCubeDB — Reference for Algorithm Display

SpeedCubeDB's OLL reference works because:
- Filtering by shape category (Dot, T-Shape, Fish) reduces the visual search space
- Vote count and move count appear with every alternative algorithm
- The primary algorithm is always above the fold; alternatives are below
- Notation is monospaced and large enough to read at arm's length

**Lesson for CubeNotch**: Structure mirrors SpeedCubeDB's information hierarchy but adds
HUD-specific needs: the algorithm must be readable while you're holding a cube, glancing
sideways, in a bright room or a dark one. Larger type, higher contrast, and less UI chrome.

---

## 10. SwiftUI Patterns Worth Using in CubeNotch

### Adaptive Glass Modifier (Backward Compatible)

```swift
extension View {
    @ViewBuilder
    func cubeNotchGlass(tint: Color = .clear, shape: some Shape = Capsule()) -> some View {
        if #available(macOS 26.0, *) {
            if tint == .clear {
                self.glassEffect(.regular, in: shape)
            } else {
                self.glassEffect(.regular.tint(tint), in: shape)
            }
        } else {
            self
                .background(shape.fill(.ultraThinMaterial))
                .overlay(shape.stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
        }
    }
}
```

### Timer Display

```swift
struct TimerDisplay: View {
    let elapsed: TimeInterval
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        Text(formatted(elapsed))
            .font(.system(size: 72, weight: .light, design: .default))
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.08),
                value: formatted(elapsed)
            )
            .foregroundStyle(.primary)
    }

    func formatted(_ t: TimeInterval) -> String {
        let minutes = Int(t) / 60
        let seconds = Int(t) % 60
        let millis  = Int((t - Double(Int(t))) * 1000) / 10
        return String(format: "%d:%02d.%02d", minutes, seconds, millis)
    }
}
```

### Algorithm Card

```swift
struct AlgorithmCard: View {
    let caseName: String     // "OLL 21"
    let groupName: String    // "T Shape"
    let primary: String      // "R U R' U' R U2 R'"
    let alternatives: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(caseName)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text(groupName)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                // Cube diagram view
            }

            Text(primary)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)

            if !alternatives.isEmpty {
                Divider()
                ForEach(alternatives.prefix(2), id: \.self) { alt in
                    Text(alt)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
```

### Size Mode Scaling

```swift
enum SizeMode: String, CaseIterable {
    case compact, medium, large
}

struct SizeTokens {
    let timerFontSize: CGFloat
    let algorithmFontSize: CGFloat
    let cardPadding: CGFloat
    let panelWidth: CGFloat

    static func for(_ mode: SizeMode) -> SizeTokens {
        switch mode {
        case .compact: return SizeTokens(timerFontSize: 48, algorithmFontSize: 13, cardPadding: 10, panelWidth: 260)
        case .medium:  return SizeTokens(timerFontSize: 72, algorithmFontSize: 15, cardPadding: 16, panelWidth: 320)
        case .large:   return SizeTokens(timerFontSize: 96, algorithmFontSize: 17, cardPadding: 20, panelWidth: 400)
        }
    }
}

@AppStorage("sizeMode") var sizeMode: SizeMode = .medium
var tokens: SizeTokens { .for(sizeMode) }
```

### Glass Fallback for Pre-Liquid Glass "Shimmer" Effect

On macOS < 26, simulate a glass border using a gradient stroke:

```swift
func glassBorder(cornerRadius: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .stroke(
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.35), location: 0.0),
                    .init(color: .white.opacity(0.08), location: 0.4),
                    .init(color: .white.opacity(0.20), location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 0.75
        )
}
```

Research from a pre-26 macOS glassmorphism project confirms that *border design* does more
for the glass illusion than surface opacity adjustments. A carefully crafted gradient stroke
that simulates light catching the rim of a glass outperforms any amount of `.opacity()` tuning.

---

## 11. Checklist Before Shipping

### Active visual direction (2026-09-11 continuation)
- Aesthetic quality is a user requirement, alongside functioning code and documented verification.
- Give the cube and primary notation clear hierarchy; group transport controls with comfortable targets, keep speed/progress secondary, and avoid repeating notation in multiple competing cards.
- Check actual native renders at compact/medium/large sizes and in light/dark, not just source-level styling.
- Record chosen layouts, inspected images and remaining gaps in `docs/VISUAL-VERIFICATION.md`.


- [ ] Timer uses `.monospacedDigit()` and `.contentTransition(.numericText())`
- [ ] Panel uses `NSPanel` with `.nonactivatingPanel` + `becomesKeyOnlyIfNeeded = true`
- [ ] No call to `NSApp.activate(ignoringOtherApps:)` on panel show
- [ ] Glass applied only to controls/toolbar, not to algorithm content
- [ ] `GlassEffectContainer` wraps multiple adjacent glass elements
- [ ] Accessibility: tested with Reduce Transparency ON
- [ ] Accessibility: tested with Reduce Motion ON
- [ ] Backward compat: falls back to `.ultraThinMaterial` on macOS < 26
- [ ] `collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]` set
- [ ] Panel position persists across app relaunches
- [ ] Blur intensity slider available in Settings
- [ ] Background tint options (neutral/dark/light/accent) in Settings
- [ ] Size mode (compact/medium/large) persists via `@AppStorage`
- [ ] No animations replay on Mission Control return or Space switch
- [ ] All three size modes tested for layout integrity

---

## Sources

- [iOS 26 Liquid Glass: Ultimate Swift/SwiftUI Reference — Conor Luddy](https://www.conor.fyi/writing/liquid-glass-reference)
- [Liquid Glass in SwiftUI: Three Patterns From Shipping Return on iOS 26 — Blake Crosley](https://blakecrosley.com/blog/liquid-glass-swiftui-patterns)
- [Liquid Glass in Swift: Official Best Practices for iOS 26 & macOS Tahoe — DEV Community](https://dev.to/diskcleankit/liquid-glass-in-swift-official-best-practices-for-ios-26-macos-tahoe-1coo)
- [Apple Liquid Glass in iOS 26: Complete SwiftUI Implementation Guide — Skyscraper](https://getskyscraper.com/blog/apple-liquid-glass-ios-26-swiftui-guide)
- [Apple introduces a delightful and elegant new software design — Apple Newsroom](https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/)
- [Applying Liquid Glass to custom views — Apple Developer Documentation](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)
- [glassEffect(_:in:) — Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:))
- [NSGlassEffectView — Apple Developer Documentation](https://developer.apple.com/documentation/appkit/nsglasseffectview)
- [NSGlassEffectView Class (AppKit) — Microsoft Learn / .NET macOS 26 Bindings](https://learn.microsoft.com/en-us/dotnet/api/appkit.nsglasseffectview?view=net-macos-26.0-10.0)
- [Build an AppKit app with the new design — WWDC25 Session 310](https://developer.apple.com/videos/play/wwdc2025/310/)
- [Build a SwiftUI app with the new design — WWDC25 Session 323](https://developer.apple.com/videos/play/wwdc2025/323/)
- [Apple reveals winners of the 2026 Apple Design Awards — Apple Newsroom](https://www.apple.com/newsroom/2026/06/apple-reveals-winners-of-the-2026-apple-design-awards/)
- [Apple Design Awards 2026 — Apple Developer](https://developer.apple.com/design/awards/)
- [A Technical Deep Dive Into the New Raycast — Raycast Blog](https://www.raycast.com/blog/a-technical-deep-dive-into-the-new-raycast)
- [SwiftUI Floating Panel: NSPanel Patterns for macOS Apps — Fazm Blog](https://fazm.ai/blog/swiftui-floating-panel)
- [Make a floating panel in SwiftUI for macOS — Cindori Developer](https://cindori.com/developer/floating-panel)
- [Dynamic dates with monospaced digits in SwiftUI — Nil Coalescing](https://nilcoalescing.com/blog/DynamicDatesWithMonospacedDigits/)
- [Best Notch Apps for MacBook 2026 — Brow App Blog](https://brow-app.com/blog/best-macbook-notch-apps-2026)
- [2026 macOS Always-on-Top Landscape Guide — Floaty / Medium](https://medium.com/@ayincat/2026-macos-always-on-top-landscape-guide-floaty-for-macos-d98c6338244e)
- [How I Built Glassmorphism on macOS 14 While Apple Requires macOS 26 — Klarity Blog](https://www.klaritydisk.com/blog/building-liquid-glass-ui-macos)
- [SpeedCubeDB OLL Algorithm Reference](https://speedcubedb.com/a/3x3/OLL)
- [CubeTime — GitHub](https://github.com/CubeLabsNZ/CubeTime)
- [Apple Human Interface Guidelines — Typography](https://developer.apple.com/design/human-interface-guidelines/macos/visual-design/typography/)
- [Apple Design System Breakdown 2026 — Superdesign](https://www.superdesign.dev/blog/apple-design-system)
- [macOS Tahoe windows have different corner radiuses — Lap Cat Software](https://lapcatsoftware.com/articles/2026/3/1.html)
