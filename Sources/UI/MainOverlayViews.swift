import SwiftUI
import AppKit

public struct ContentView: View {
    @Environment(\.cubeStateManager) private var manager
    @EnvironmentObject private var solveTimer: SolveTimer
    @AppStorage("sizeMode") private var sizeMode: SizeMode = .medium
    @AppStorage("anchorPosition") private var anchorPosition: Anchor = .topRight
    @AppStorage("followActiveScreen") private var followActiveScreen: Bool = false
    @AppStorage("preferredScreen") private var preferredScreen: String = ""
    @AppStorage("blurIntensity") private var blurIntensity: Double = 0.5
    @AppStorage("backgroundTint") private var backgroundTint: String = "neutral"
    @State private var showSettings = false
    @State private var caseCategory: String = "OLL" // "F2L" | "OLL" | "PLL"
    @State private var detailCase: CubeCase? = nil
    @State private var launchAtLoginEnabled: Bool = LaunchAtLogin.isEnabled
    @State private var mode: String = "Cases" // "Cases" | "Timer"
    @State private var showSavedFeedback = false
    @State private var showCopiedFeedback = false
    @State private var searchText: String = ""

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
        let base: [CubeCase]
        switch caseCategory {
        case "F2L": base = F2LDatabase.f2lCases
        case "OLL": base = AlgorithmDatabase.ollCases
        case "PLL": base = AlgorithmDatabase.pllCases
        default: base = AlgorithmDatabase.ollCases
        }
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return base }
        let q = searchText.lowercased()
        return base.filter { c in
            c.name.lowercased().contains(q) ||
            c.caseType.lowercased().contains(q) ||
            String(c.caseNumber).contains(q) ||
            c.primaryAlgorithm.lowercased().contains(q)
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
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(Color.black.opacity(blurIntensity * 0.45))
            .overlay(tintColor.opacity(0.10))
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
        VStack(spacing: 4) {
            if mode == "Cases" && detailCase == nil {
                TextField("Search cases…", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)
                    .padding(.horizontal, 8)
                    .onChange(of: caseCategory) { _, _ in
                        searchText = ""
                    }
            }
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

                HStack {
                    Text(c.primaryAlgorithm)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Primary algorithm: \(c.primaryAlgorithm)")

                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(c.primaryAlgorithm, forType: .string)
                        withAnimation { showCopiedFeedback = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation { showCopiedFeedback = false }
                        }
                    }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Copy primary algorithm")
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 10)

                if showCopiedFeedback {
                    Text("Copied")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
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

            VStack(alignment: .leading, spacing: 4) {
                Text("Blur")
                    .font(.caption.weight(.medium))
                Slider(value: $blurIntensity, in: 0...1)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Tint")
                    .font(.caption.weight(.medium))
                HStack(spacing: 8) {
                    ForEach(["neutral", "dark", "light", "blue", "purple", "green"], id: \.self) { tint in
                        Circle()
                            .fill(tintSwatchColor(for: tint))
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.6), lineWidth: backgroundTint == tint ? 2 : 0)
                            )
                            .onTapGesture {
                                backgroundTint = tint
                            }
                    }
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

    private var tintColor: Color {
        switch backgroundTint {
        case "dark": return .black
        case "light": return .white
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        default: return .clear
        }
    }

    private func tintSwatchColor(for tint: String) -> Color {
        switch tint {
        case "dark": return .black
        case "light": return .white
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        default: return Color.gray.opacity(0.3)
        }
    }
}
