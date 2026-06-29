import SwiftUI
import AppKit
import Carbon

public struct ContentView: View {
    @Environment(\.cubeStateManager) private var manager
    @EnvironmentObject private var solveTimer: SolveTimer
    @EnvironmentObject private var trainerStore: TrainerStore
    @EnvironmentObject private var timeStore: TimeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @AppStorage(UDKey.sizeMode) private var sizeMode: SizeMode = .medium
    @AppStorage(UDKey.anchorPosition) private var anchorPosition: Anchor = .topRight
    @AppStorage(UDKey.followActiveScreen) private var followActiveScreen: Bool = false
    @AppStorage(UDKey.preferredScreen) private var preferredScreen: String = ""
    @AppStorage(UDKey.blurIntensity) private var blurIntensity: Double = 0.5
    @AppStorage(UDKey.backgroundTint) private var backgroundTint: String = "neutral"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showSettings = false
    @State private var showOnboarding = false
    @State private var showAccessibilityPrompt = false
    @State private var pulseHotkey = false
    @State private var hasPulsedHotkeyThisSession = false
    @State private var caseCategory: String = "OLL" // "F2L" | "OLL" | "PLL"
    @State private var detailCase: CubeCase? = nil
    @State private var launchAtLoginEnabled: Bool = LaunchAtLogin.isEnabled
    @State private var mode: String = "Cases" // "Cases" | "Timer" | "Train" | "Stats"
    @State private var showSavedFeedback = false
    @State private var showCopiedFeedback = false
    @State private var copiedAltIndex: Int? = nil
    @State private var searchText: String = ""

    // 13A-5: Recent and Pinned
    @State private var recentCaseIDs: [String] = []
    @State private var pinnedCaseIDs: Set<String> = []
    private let recentKey = UDKey.recentCaseIDs
    private let pinnedKey = UDKey.pinnedCaseIDs

    // 13A-4 Hotkey capture
    @State private var listeningForHotkey = false

    // Box so the monitor token can be mutated from inside the NSEvent closure
    private final class HotkeyBox {
        var monitor: Any?
    }
    @State private var hotkeyBox = HotkeyBox()
    @State private var _hotkeyEventMonitor: Any? = nil

    private var hotkeyEventMonitor: Any? {
        get { _hotkeyEventMonitor }
        set { _hotkeyEventMonitor = newValue }
    }

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

    private func moveCount(_ alg: String) -> Int {
        alg.split(separator: " ").filter { !$0.isEmpty }.count
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
                .background(reduceTransparency ? .regularMaterial : .thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(Color.black.opacity(blurIntensity * 0.45))
            .overlay(tintColor.opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)

            settingsDrawer
                .offset(x: showSettings ? (currentWindowSize.width - drawerWidth) : currentWindowSize.width)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: showSettings)
        }
        .padding(8)
        .onReceive(NotificationCenter.default.publisher(for: .cubeStateDidChange)) { _ in }
        .onTapGesture(count: 2) {
            // Double-click anywhere on the overlay -> spring hide
            if !reduceMotion {
                NotificationCenter.default.post(name: .requestAnimatedHide, object: nil)
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView {
                hasCompletedOnboarding = true
                showOnboarding = false
            }
        }
        .sheet(isPresented: $showAccessibilityPrompt) {
            accessibilityPromptView
        }
        .onAppear {
            if !hasCompletedOnboarding {
                // show after a tiny delay so the HUD is visible first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showOnboarding = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestAccessibilityPrompt)) { _ in
            showAccessibilityPrompt = true
        }
    }

    private func takeScreenshot() {
        guard let img = ScreenshotService.captureOverlay() else { return }
        ScreenshotService.copyToClipboard(img)
        if let url = ScreenshotService.saveToDesktop(img) {
            // brief feedback
            if reduceMotion {
                showSavedFeedback = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showSavedFeedback = false }
            } else {
                withAnimation { showSavedFeedback = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation { showSavedFeedback = false }
                }
            }
            // Optional: log or print path in console for now
            print("Screenshot saved:", url.path)
        }
    }

    private var browserHeader: some View {
        VStack(spacing: 4) {
            Group {
                if #available(macOS 26.0, *) {
                    GlassEffectContainer(spacing: 8) { headerTopRow }
                } else {
                    headerTopRow
                }
            }
            if detailCase == nil && mode == "Cases" {
                Group {
                    if #available(macOS 26.0, *) {
                        GlassEffectContainer(spacing: 8) { categoryRow }
                    } else {
                        categoryRow
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var categoryRow: some View {
        Picker("", selection: $caseCategory) {
            Text("F2L").tag("F2L")
            Text("OLL").tag("OLL")
            Text("PLL").tag("PLL")
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Case category")
        .frame(maxWidth: .infinity)
        .cubeNotchGlass(cornerRadius: 8)
    }

    private var headerContent: some View { headerTopRow }

    private var headerTopRow: some View {
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
                    Text("Train").tag("Train")
                    Text("Stats").tag("Stats")
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Mode")
                .cubeNotchGlass(cornerRadius: 8)
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
            } else if mode == "Timer" {
                Text("Timer")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
            } else if mode == "Train" {
                Text("Train")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
            } else {
                Text("Stats")
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
                .cubeNotchGlass(cornerRadius: 6)
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
                .cubeNotchGlass(cornerRadius: 6)
            }

            if detailCase == nil {
                Button(action: takeScreenshot) {
                    Image(systemName: "camera")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Screenshot overlay to Desktop + clipboard")
                .accessibilityLabel("Screenshot")
                .cubeNotchGlass(cornerRadius: 6)
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
            .cubeNotchGlass(cornerRadius: 6)
            .onChange(of: showSettings) { _, newValue in
                if newValue && !hasPulsedHotkeyThisSession {
                    hasPulsedHotkeyThisSession = true
                    pulseHotkey = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        withAnimation { pulseHotkey = false }
                    }
                }
            }
        }
    }

    private var browserMain: some View {
        Group {
            if let detail = detailCase {
                caseDetailView(for: detail)
            } else if mode == "Timer" {
                TimerView()
            } else if mode == "Train" {
                TrainerView()
            } else if mode == "Stats" {
                StatsView()
            } else {
                caseListView
            }
        }
        .padding(.bottom, 8)
    }

    private var caseListView: some View {
        VStack(spacing: 0) {
            if mode == "Cases" && detailCase == nil {
                TextField("Search cases…", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 2)
                    .onChange(of: caseCategory) { _, _ in
                        searchText = ""
                    }
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    // 13A-5 Recent + Pinned
                    if searchText.isEmpty && mode == "Cases" {
                        let recents = recentCaseIDs.compactMap { id in filteredCases.first(where: { $0.id == id }) }.prefix(5)
                        if !recents.isEmpty {
                            Text("Recent").font(.system(size: 13, design: .rounded)).foregroundStyle(.secondary).padding(.horizontal, 12).padding(.top, 4)
                            ForEach(Array(recents)) { c in
                                caseRow(for: c)
                            }
                            Divider().padding(.horizontal, 8)
                        }
                        let pinned = filteredCases.filter { pinnedCaseIDs.contains($0.id) }
                        if !pinned.isEmpty {
                            Text("Pinned").font(.caption.weight(.medium)).foregroundStyle(.secondary).padding(.horizontal, 12)
                            ForEach(pinned) { c in
                                caseRow(for: c)
                            }
                            Divider().padding(.horizontal, 8)
                        }
                    }

                    ForEach(filteredCases.filter { !pinnedCaseIDs.contains($0.id) && !recentCaseIDs.contains($0.id) }) { c in
                        caseRow(for: c)
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(maxHeight: .infinity)
        }
        .onAppear(perform: loadRecentPinned)
    }

    private func caseRow(for c: CubeCase) -> some View {
        Button(action: {
            detailCase = c
            addToRecent(c.id)
        }) {
            HStack(spacing: 10) {
                // Diagram thumbnail — OLL shows U face only (the recognizable shape),
                // PLL shows full cross (side colors are the recognition cue)
                CubeStateView(
                    currentCase: c,
                    visualMode: .preExecution,
                    sizeMode: .compact,
                    uFaceOnly: c.caseType != "PLL"
                )
                .frame(width: c.caseType == "PLL" ? 52 : 44, height: c.caseType == "PLL" ? 52 : 44)
                .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(c.caseType) \(c.caseNumber)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(c.name)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 4) {
                    if c.id == manager.currentCase.id {
                        Image(systemName: "checkmark")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if pinnedCaseIDs.contains(c.id) {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                c.id == manager.currentCase.id
                    ? Color.white.opacity(0.08)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
            .accessibilityLabel("\(c.caseType) \(c.caseNumber) \(c.name)\(c.id == manager.currentCase.id ? ", current" : "")")
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(pinnedCaseIDs.contains(c.id) ? "Unpin" : "Pin to top") {
                togglePin(c.id)
            }
        }
    }

    private func addToRecent(_ id: String) {
        recentCaseIDs.removeAll { $0 == id }
        recentCaseIDs.insert(id, at: 0)
        if recentCaseIDs.count > 8 { recentCaseIDs.removeLast() }
        UserDefaults.standard.set(recentCaseIDs, forKey: UDKey.recentCaseIDs)
    }

    private func togglePin(_ id: String) {
        if pinnedCaseIDs.contains(id) {
            pinnedCaseIDs.remove(id)
        } else {
            pinnedCaseIDs.insert(id)
        }
        UserDefaults.standard.set(Array(pinnedCaseIDs), forKey: UDKey.pinnedCaseIDs)
    }

    private func loadRecentPinned() {
        if let rec = UserDefaults.standard.stringArray(forKey: recentKey) {
            recentCaseIDs = rec
        }
        if let pin = UserDefaults.standard.stringArray(forKey: pinnedKey) {
            pinnedCaseIDs = Set(pin)
        }
    }

    private func caseDetailView(for c: CubeCase) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Diagram
                Text("RECOGNIZE THIS:")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                CubeStateView(currentCase: c, visualMode: .preExecution, sizeMode: .large)
                    .frame(width: 200, height: 160)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(.horizontal, 10)

                // Primary algorithm
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("PRIMARY")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.tertiary)
                            .tracking(0.5)
                        Spacer()
                        Text("\(moveCount(c.primaryAlgorithm)) moves")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                        if showCopiedFeedback {
                            Text("Copied")
                                .font(.system(size: 10))
                                .foregroundStyle(.green)
                                .transition(.opacity)
                        }
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(c.primaryAlgorithm, forType: .string)
                            withAnimation { showCopiedFeedback = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation { showCopiedFeedback = false }
                            }
                        } label: {
                            Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(showCopiedFeedback ? Color.green : .secondary)
                    }
                    .padding(.horizontal, 12)

                    Text(c.primaryAlgorithm)
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 10)
                        .accessibilityLabel("Primary: \(c.primaryAlgorithm)")
                }

                // Alternatives
                if !c.alternativeAlgorithms.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ALTERNATIVES")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.tertiary)
                            .tracking(0.5)
                            .padding(.horizontal, 12)

                        VStack(spacing: 3) {
                            ForEach(Array(c.alternativeAlgorithms.enumerated()), id: \.offset) { idx, alt in
                                altRow(idx: idx, alt: alt)
                            }
                        }
                    }
                }

                // Recognition tip
                if let tip = c.recognitionTip {
                    HStack(spacing: 6) {
                        Image(systemName: "eye")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                        Text(tip)
                            .font(.system(size: 12).italic())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                }
            }
            .padding(.bottom, 8)
        }
    }

    private func altRow(idx: Int, alt: String) -> some View {
        HStack(spacing: 8) {
            Text("\(idx + 1)")
                .font(.system(size: 10))
                .foregroundStyle(Color.secondary.opacity(0.4))
                .frame(width: 12, alignment: .trailing)
            Text(alt)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(moveCount(alt))")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(alt, forType: .string)
                withAnimation { copiedAltIndex = idx }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        if copiedAltIndex == idx { copiedAltIndex = nil }
                    }
                }
            } label: {
                Image(systemName: (copiedAltIndex == idx) ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
            .foregroundStyle(copiedAltIndex == idx ? .green : Color.secondary.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .padding(.horizontal, 10)
        .accessibilityLabel("Alternative \(idx + 1): \(alt)")
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

            Toggle("WCA Inspection", isOn: Binding(
                get: { UserDefaults.standard.object(forKey: UDKey.wcaInspection) as? Bool ?? true },
                set: { UserDefaults.standard.set($0, forKey: UDKey.wcaInspection) }
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

            // 13A-4 Hotkey customizer + 18A-3 tip + pulse
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Hotkey").font(.caption.weight(.medium))
                    if pulseHotkey {
                        Circle()
                            .fill(Color.accentColor.opacity(0.8))
                            .frame(width: 5, height: 5)
                            .transition(.opacity)
                    }
                }
                Text(listeningForHotkey ? "Press new combo…" : GlobalHotKeyManager.shared.currentHotkeyDisplay())
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(listeningForHotkey ? .orange : .primary)
                    .scaleEffect(pulseHotkey ? 1.04 : 1.0)
                    .animation(pulseHotkey ? .easeInOut(duration: 0.6).repeatCount(2, autoreverses: true) : .default, value: pulseHotkey)
                Button(listeningForHotkey ? "Listening…" : "Change…") {
                    startHotkeyCapture()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(listeningForHotkey)

                Text("Tip: Ctrl+Shift+Space works even while another app is in focus")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }

            Button("Close") {
                showSettings = false
            }
            .font(.caption)

            Divider()

            Button("Show Intro Again") {
                showSettings = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showOnboarding = true
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(width: drawerWidth, height: currentWindowSize.height)
        .background(reduceTransparency ? .regularMaterial : .thinMaterial)
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

    // 13A-4: Hotkey capture (listening mode)
    // Note: Full live capture is wired in GlobalHotKeyManager + AppDelegate.
    // This stub just provides the "listening" UI state for now.
    private func startHotkeyCapture() {
        listeningForHotkey = true

        // Remove any previous monitor
        if let mon = hotkeyBox.monitor {
            NSEvent.removeMonitor(mon)
            hotkeyBox.monitor = nil
        }

        let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let keyCode = event.keyCode
            var mods: UInt32 = 0
            let flags = event.modifierFlags
            if flags.contains(.command) { mods |= UInt32(cmdKey) }
            if flags.contains(.option)  { mods |= UInt32(optionKey) }
            if flags.contains(.shift)   { mods |= UInt32(shiftKey) }
            if flags.contains(.control) { mods |= UInt32(controlKey) }

            // Guard invalid combos
            if keyCode == 49 && mods == 0 { return event } // Space alone
            if keyCode == 53 || keyCode == 36 { return event } // Esc / Return

            GlobalHotKeyManager.shared.setHotkey(keyCode: UInt32(keyCode), modifiers: mods) { }

            // Ask AppDelegate to rebind (on main)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .requestHotkeyRebind, object: nil)
            }

            DispatchQueue.main.async {
                self.listeningForHotkey = false
                if let mon = self.hotkeyBox.monitor {
                    NSEvent.removeMonitor(mon)
                    self.hotkeyBox.monitor = nil
                }
            }
            return nil // consume
        }

        hotkeyBox.monitor = monitor
    }

    // Accessibility permission prompt (shown if CGEventTap fails at launch)
    private var accessibilityPromptView: some View {
        VStack(spacing: 12) {
            Text("Spacebar Timer Needs Accessibility Access")
                .font(.headline)
            Text("CubeNotch uses a global event tap for the spacebar timer. Without Accessibility permission the timer won't respond while other apps are focused.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)

            HStack {
                Button("Open System Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Retry") {
                    showAccessibilityPrompt = false
                    NotificationCenter.default.post(name: .requestRetryEventTap, object: nil)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .frame(width: 320)
    }
}


