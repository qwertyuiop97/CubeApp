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
    @State private var launchAtLoginError: String?
    @State private var mode: String = "Cases" // "Cases" | "Timer" | "Train" | "Stats"
    @State private var showSavedFeedback = false
    @State private var showCopiedFeedback = false
    @State private var copiedAltIndex: Int? = nil
    @State private var searchText: String = ""

    // Recent and pinned cases
    @State private var recentCaseIDs: [String] = []
    @State private var pinnedCaseIDs: Set<String> = []
    private let recentKey = UDKey.recentCaseIDs
    private let pinnedKey = UDKey.pinnedCaseIDs

    // Hotkey capture
    @State private var listeningForHotkey = false
    @State private var hotkeyError: String?
    @State private var hotkeyCapture = HotkeyCaptureController.usingAppKit()

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

    private func moveCount(_ alg: String) -> String {
        guard let count = try? CubeEngine.sliceTurnCount(alg) else { return "—" }
        return String(count)
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
        .onDisappear { stopHotkeyCapture() }
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
        if ScreenshotService.saveToDesktop(img) != nil {
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
                if !newValue { stopHotkeyCapture() }
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
                HUDCaseDetailView(
                    cubeCase: detail,
                    visualMode: manager.visualMode,
                    sizeMode: sizeMode,
                    showCopiedFeedback: $showCopiedFeedback,
                    copiedAltIndex: $copiedAltIndex
                )
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
                    let sections = CaseListSections(
                        cases: filteredCases, recentIDs: recentCaseIDs,
                        pinnedIDs: pinnedCaseIDs, showHistory: searchText.isEmpty && mode == "Cases"
                    )
                    if !sections.pinned.isEmpty {
                        Text("Pinned").font(.caption.weight(.medium)).foregroundStyle(.secondary).padding(.horizontal, 12)
                        ForEach(sections.pinned) { c in caseRow(for: c) }
                        Divider().padding(.horizontal, 8)
                    }
                    if !sections.recent.isEmpty {
                        Text("Recent").font(.system(size: 13, design: .rounded)).foregroundStyle(.secondary).padding(.horizontal, 12).padding(.top, 4)
                        ForEach(sections.recent) { c in caseRow(for: c) }
                        Divider().padding(.horizontal, 8)
                    }
                    ForEach(sections.remaining) { c in
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
        recentCaseIDs = CaseListSections.remember(id, in: recentCaseIDs)
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
                    let result = LaunchAtLogin.apply(newValue)
                    launchAtLoginEnabled = result.isEnabled
                    launchAtLoginError = result.errorMessage
                }
            ))
            if let launchAtLoginError {
                Text(launchAtLoginError)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }

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

            // Hotkey customizer
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
                Button(listeningForHotkey ? "Cancel" : "Change…") {
                    if listeningForHotkey { stopHotkeyCapture() }
                    else { startHotkeyCapture() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                if let hotkeyError {
                    Text(hotkeyError).font(.caption2).foregroundStyle(.red)
                }

                Text("The configured shortcut works while another app is in focus. Escape cancels recording.")
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

    // Local capture keeps key input scoped to the overlay. Change… may request temporary key focus.
    private func startHotkeyCapture() {
        listeningForHotkey = true
        hotkeyError = nil

        guard let overlay = NSApp.windows.compactMap({ $0 as? FloatingOverlayWindow }).first else {
            listeningForHotkey = false
            hotkeyError = "Overlay is not available for recording."
            return
        }

        hotkeyCapture.start(on: overlay) { event in
            let keyCode = event.keyCode
            var mods: UInt32 = 0
            let flags = event.modifierFlags
            if flags.contains(.command) { mods |= UInt32(cmdKey) }
            if flags.contains(.option)  { mods |= UInt32(optionKey) }
            if flags.contains(.shift)   { mods |= UInt32(shiftKey) }
            if flags.contains(.control) { mods |= UInt32(controlKey) }

            if keyCode == 53 {
                self.stopHotkeyCapture()
                return nil
            }
            let result = GlobalHotKeyManager.shared.setHotkey(keyCode: UInt32(keyCode), modifiers: mods)
            guard result == .bound else {
                self.hotkeyError = result == .registrationFailed
                    ? "That shortcut is unavailable. Try another combination."
                    : "Space alone and Return are reserved. Choose another shortcut."
                return nil
            }

            DispatchQueue.main.async {
                self.stopHotkeyCapture()
            }
            return nil
        }
    }

    private func stopHotkeyCapture() {
        listeningForHotkey = false
        hotkeyCapture.stop()
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

struct HUDCaseDetailView: View {
    let cubeCase: CubeCase
    let visualMode: VisualMode
    let sizeMode: SizeMode
    @Binding var showCopiedFeedback: Bool
    @Binding var copiedAltIndex: Int?
    var scrolls: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var playbackShowsLiveNotation: Bool {
        PlaybackPresentation(
            visualMode: visualMode,
            loadError: nil,
            reduceMotion: reduceMotion,
            hasLoadedPlayback: true
        ).showsLiveNotation
    }

    var body: some View {
        if scrolls {
            ScrollView { detailStack }
        } else {
            detailStack
        }
    }

    private var detailStack: some View {
        VStack(alignment: .leading, spacing: 8) {
                Text(visualMode == .textOnly ? "ALGORITHM" : "PLAYBACK")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)

                AlgorithmPlaybackView(
                    cubeCase: cubeCase,
                    algorithm: cubeCase.primaryAlgorithm,
                    visualMode: visualMode,
                    sizeMode: sizeMode
                )
                .id("\(cubeCase.id)|\(cubeCase.primaryAlgorithm)")
                .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                primaryCopyChrome

                if !cubeCase.alternativeAlgorithms.isEmpty {
                    alternativesSection
                }

                if let tip = cubeCase.recognitionTip {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "eye")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                            .padding(.top, 1)
                        Text(tip)
                            .font(.system(size: 12).italic())
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
    }

    private var primaryCopyChrome: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("PRIMARY")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                Spacer()
                Text("\(moveCount(cubeCase.primaryAlgorithm)) moves")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
                if showCopiedFeedback {
                    Text("Copied")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.green)
                }
                Button(action: copyPrimary) {
                    Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(showCopiedFeedback ? Color.green : .secondary)
                .accessibilityLabel("Copy primary algorithm")
            }

            if CaseDetailCopyPolicy.showsStandaloneNotation(playbackShowsLiveNotation: playbackShowsLiveNotation) {
                Text(cubeCase.primaryAlgorithm)
                    .font(.system(size: PlaybackLayoutMetrics.notationSize(for: sizeMode), weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityLabel("Primary: \(cubeCase.primaryAlgorithm)")
            }
        }
        .padding(.horizontal, 8)
    }

    private var alternativesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ALTERNATIVES")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .tracking(0.6)
                .padding(.horizontal, 8)

            VStack(spacing: 4) {
                ForEach(Array(cubeCase.alternativeAlgorithms.enumerated()), id: \.offset) { idx, alt in
                    altRow(idx: idx, alt: alt)
                }
            }
        }
    }

    private func altRow(idx: Int, alt: String) -> some View {
        HStack(spacing: 8) {
            Text("\(idx + 1)")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.tertiary)
                .frame(width: 16, alignment: .trailing)
            Text(alt)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(moveCount(alt))")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .monospacedDigit()
            Button {
                copyString(alt)
                setCopiedAlt(idx)
            } label: {
                Image(systemName: copiedAltIndex == idx ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(copiedAltIndex == idx ? Color.green : Color.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityLabel("Alternative \(idx + 1): \(alt)")
    }

    private func copyPrimary() {
        copyString(cubeCase.primaryAlgorithm)
        if reduceMotion {
            showCopiedFeedback = true
        } else {
            withAnimation { showCopiedFeedback = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if reduceMotion {
                showCopiedFeedback = false
            } else {
                withAnimation { showCopiedFeedback = false }
            }
        }
    }

    private func setCopiedAlt(_ idx: Int) {
        if reduceMotion {
            copiedAltIndex = idx
        } else {
            withAnimation { copiedAltIndex = idx }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if copiedAltIndex == idx {
                if reduceMotion {
                    copiedAltIndex = nil
                } else {
                    withAnimation { copiedAltIndex = nil }
                }
            }
        }
    }

    private func copyString(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func moveCount(_ alg: String) -> String {
        guard let count = try? CubeEngine.sliceTurnCount(alg) else { return "—" }
        return String(count)
    }
}
