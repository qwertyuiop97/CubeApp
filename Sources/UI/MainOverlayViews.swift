import SwiftUI
import AppKit

public struct ContentView: View {
    @Environment(\.cubeStateManager) private var manager
    @EnvironmentObject private var solveTimer: SolveTimer
    @AppStorage("sizeMode") private var sizeMode: SizeMode = .medium
    @AppStorage("anchorPosition") private var anchorPosition: Anchor = .topRight
    @AppStorage("followActiveScreen") private var followActiveScreen: Bool = false
    @AppStorage("preferredScreen") private var preferredScreen: String = ""
    @State private var showSettings = false
    @State private var caseCategory: String = "OLL" // "F2L" | "OLL" | "PLL"
    @State private var detailCase: CubeCase? = nil
    @State private var launchAtLoginEnabled: Bool = LaunchAtLogin.isEnabled
    @State private var mode: String = "Cases" // "Cases" | "Timer"
    @State private var showSavedFeedback = false

    private var sizeBinding: Binding<SizeMode> {
        Binding(
            get: { sizeMode },
            set: { newValue in
                sizeMode = newValue
                manager.setSizeMode(newValue)
            }
        )
    }

    private var anchorBinding: Binding<Anchor> {
        Binding(
            get: { anchorPosition },
            set: { newValue in
                anchorPosition = newValue
                manager.setAnchor(newValue)
            }
        )
    }

    private var filteredCases: [CubeCase] {
        switch caseCategory {
        case "F2L": return F2LDatabase.f2lCases
        case "OLL": return AlgorithmDatabase.ollCases
        case "PLL": return AlgorithmDatabase.pllCases
        default: return AlgorithmDatabase.ollCases
        }
    }

    private var currentWindowSize: NSSize {
        manager.sizeMode.windowSize
    }

    private var drawerWidth: CGFloat {
        260
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                browserHeader
                browserMain
            }
            .frame(width: currentWindowSize.width, height: currentWindowSize.height)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)

            settingsDrawer
                .offset(x: showSettings ? (currentWindowSize.width - drawerWidth) : currentWindowSize.width)
                .animation(.easeInOut(duration: 0.2), value: showSettings)
        }
        .padding(8)
        .onReceive(NotificationCenter.default.publisher(for: .cubeStateDidChange)) { _ in }
        .onTapGesture(count: 2) {
            // Double-click anywhere on the overlay -> spring hide
            NotificationCenter.default.post(name: .requestAnimatedHide, object: nil)
        }
    }

    private func takeScreenshot() {
        guard let img = ScreenshotService.captureOverlay() else { return }
        ScreenshotService.copyToClipboard(img)
        if let url = ScreenshotService.saveToDesktop(img) {
            // brief feedback
            withAnimation { showSavedFeedback = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { showSavedFeedback = false }
            }
            // Optional: log or print path in console for now
            print("Screenshot saved:", url.path)
        }
    }

    private var browserHeader: some View {
        HStack(spacing: 8) {
            if detailCase != nil {
                Button(action: { detailCase = nil }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Back to list")
            } else {
                Picker("", selection: $mode) {
                    Text("Cases").tag("Cases")
                    Text("Timer").tag("Timer")
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
                .accessibilityLabel("Mode")
            }

            if detailCase == nil && mode == "Cases" {
                Picker("", selection: $caseCategory) {
                    Text("F2L").tag("F2L")
                    Text("OLL").tag("OLL")
                    Text("PLL").tag("PLL")
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
                .accessibilityLabel("Case category")
            }

            Spacer()

            if let d = detailCase {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(d.name)
                        .font(.headline.weight(.semibold))
                    Text("\(d.caseType) \(d.caseNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if mode == "Cases" {
                Text("Browse")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
            } else {
                Text("Timer")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if detailCase == nil && mode == "Cases" {
                Button(action: manager.randomCase) {
                    Image(systemName: "shuffle")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Random case")
                .accessibilityLabel("Random case")
            } else if detailCase != nil {
                Button(action: {
                    if let d = detailCase {
                        manager.selectCase(d)
                        detailCase = nil
                    }
                }) {
                    Text("Use this")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityLabel("Use this case")
            }

            if detailCase == nil {
                Button(action: takeScreenshot) {
                    Image(systemName: "camera")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Screenshot overlay to Desktop + clipboard")
                .accessibilityLabel("Screenshot")
            }

            if showSavedFeedback {
                Text("Saved")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }

            Button(action: { showSettings.toggle() }) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel(showSettings ? "Close settings" : "Open settings")
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var browserMain: some View {
        Group {
            if let detail = detailCase {
                caseDetailView(for: detail)
            } else if mode == "Timer" {
                TimerView()
            } else {
                caseListView
            }
        }
        .padding(.bottom, 8)
    }

    private var caseListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(filteredCases) { c in
                    Button(action: {
                        detailCase = c
                    }) {
                        HStack {
                            Text("\(c.caseNumber). \(c.name)")
                                .font(.system(size: manager.sizeMode == .compact ? 12 : 13))
                                .foregroundStyle(.primary)
                            Spacer()
                            if c.id == manager.currentCase.id {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            c.id == manager.currentCase.id
                                ? Color.white.opacity(0.08)
                                : Color.clear
                        )
                        .cornerRadius(6)
                        .accessibilityLabel("\(c.caseType) \(c.caseNumber) \(c.name)\(c.id == manager.currentCase.id ? ", current" : "")")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private func caseDetailView(for c: CubeCase) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            CubeStateView(currentCase: c, visualMode: manager.visualMode, sizeMode: manager.sizeMode)
                .frame(height: manager.sizeMode == .compact ? 110 : 150)
                .padding(.horizontal, 10)

            VStack(alignment: .leading, spacing: 4) {
                Text("Primary")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)

                Text(c.primaryAlgorithm)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
                    .padding(.horizontal, 10)
                    .accessibilityLabel("Primary algorithm: \(c.primaryAlgorithm)")
            }

            if !c.alternativeAlgorithms.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alternatives")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)

                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(Array(c.alternativeAlgorithms.enumerated()), id: \.offset) { idx, alt in
                            Text(alt)
                                .font(.system(.caption, design: .monospaced))
                                .padding(.vertical, 3)
                                .padding(.horizontal, 8)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 4))
                                .accessibilityLabel("Alternative \(idx + 1): \(alt)")
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }

            Spacer(minLength: 4)
        }
    }

    private var settingsDrawer: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(.headline)

            Picker("Size", selection: sizeBinding) {
                ForEach(SizeMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue.capitalized).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Picker("Visual", selection: Binding(
                get: { manager.visualMode },
                set: { manager.setVisualMode($0) }
            )) {
                ForEach(VisualMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue.replacingOccurrences(of: "preExecution", with: "Pre")).tag(mode)
                }
            }

            Picker("Anchor", selection: anchorBinding) {
                ForEach(Anchor.allCases, id: \.self) { anchor in
                    Text(shortAnchorLabel(anchor)).tag(anchor)
                }
            }

            Toggle("Follow active screen", isOn: Binding(
                get: { followActiveScreen },
                set: { newValue in
                    followActiveScreen = newValue
                    manager.setFollowActiveScreen(newValue)
                }
            ))

            Toggle("Launch at login", isOn: Binding(
                get: { launchAtLoginEnabled },
                set: { newValue in
                    launchAtLoginEnabled = newValue
                    _ = LaunchAtLogin.setEnabled(newValue)
                }
            ))

            Picker("Monitor", selection: Binding(
                get: { preferredScreen },
                set: { newValue in
                    preferredScreen = newValue
                    manager.setPreferredScreenName(newValue)
                }
            )) {
                Text("Auto").tag("")
                ForEach(NSScreen.screens, id: \.localizedName) { screen in
                    Text(screen.localizedName).tag(screen.localizedName)
                }
            }

            Button("Close") {
                showSettings = false
            }
            .font(.caption)
        }
        .padding(12)
        .frame(width: drawerWidth, height: currentWindowSize.height)
        .background(.regularMaterial)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color.white.opacity(0.1)),
            alignment: .leading
        )
    }

    private func shortAnchorLabel(_ anchor: Anchor) -> String {
        switch anchor {
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        case .notch: return "Notch"
        case .bottomCenter: return "Bottom Center"
        }
    }
}

public struct CubeCanvasView: View {
    let currentCase: CubeCase
    let visualMode: VisualMode

    public var body: some View {
        Canvas { context, size in
            drawTopDownCube(context: context, size: size)
        }
        .background(Color.black.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func drawTopDownCube(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let face = min(w, h) * 0.82
        let s = face / 3
        let ox = (w - face) / 2
        let oy = (h - face) / 2 + 4

        let colors: [Color] = [
            .white, .yellow, .red, .orange, .blue, .green
        ]

        // Draw 3x3 grid representing top face (U) + front face hint
        for row in 0..<3 {
            for col in 0..<3 {
                let x = ox + CGFloat(col) * s
                let y = oy + CGFloat(row) * s
                let rect = CGRect(x: x + 1, y: y + 1, width: s - 2, height: s - 2)

                let stickerColor: Color
                if row == 1 && col == 1 {
                    stickerColor = .gray // center
                } else {
                    // Use deterministic color cycling based on case number
                    let idx = (currentCase.caseNumber + row * 3 + col) % colors.count
                    stickerColor = colors[idx]
                }

                context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(stickerColor))
                context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(.black.opacity(0.5)), lineWidth: 1)
            }
        }

        // Simple U-layer label
        context.draw(Text("U").font(.caption2.bold()), at: CGPoint(x: ox + face / 2, y: oy - 12))
    }
}
