import SwiftUI

/// Layout rules for live playback chrome. Tests cover error/diagram/motion
/// decisions here because SwiftUI `accessibilityReduceMotion` is read-only.
struct PlaybackPresentation: Equatable {
    static let gatesDiagramOnSuccessfulLoad = true

    let showsDiagram: Bool
    let showsLiveNotation: Bool
    let showsTransport: Bool
    let errorMessage: String?
    let diagramAnimationDuration: Double?

    init(
        visualMode: VisualMode,
        loadError: AlgorithmAnimator.LoadError?,
        reduceMotion: Bool,
        hasLoadedPlayback: Bool
    ) {
        switch loadError {
        case .none:
            showsDiagram = hasLoadedPlayback && visualMode != .textOnly
            showsLiveNotation = hasLoadedPlayback
            showsTransport = hasLoadedPlayback
            errorMessage = nil
            diagramAnimationDuration = (reduceMotion || !hasLoadedPlayback) ? nil : 0.12
        case .emptyAlgorithm:
            showsDiagram = false
            showsLiveNotation = false
            showsTransport = false
            errorMessage = "Algorithm is empty."
            diagramAnimationDuration = nil
        case .invalidToken(let token):
            showsDiagram = false
            showsLiveNotation = false
            showsTransport = false
            errorMessage = "Invalid move “\(token)”."
            diagramAnimationDuration = nil
        }
    }
}

/// Playback already highlights the active algorithm. Keep copy/move-count
/// chrome; only dump the string again when live notation is hidden (errors).
enum CaseDetailCopyPolicy {
    static func showsStandaloneNotation(playbackShowsLiveNotation: Bool) -> Bool {
        !playbackShowsLiveNotation
    }
}

enum PlaybackLayoutMetrics {
    static func diagramSize(for sizeMode: SizeMode) -> CGSize {
        switch sizeMode {
        case .compact: return CGSize(width: 136, height: 112)
        case .medium: return CGSize(width: 184, height: 148)
        case .large: return CGSize(width: 320, height: 256)
        }
    }

    static func notationSize(for sizeMode: SizeMode) -> CGFloat {
        switch sizeMode {
        case .compact: return 13
        case .medium, .large: return 15
        }
    }

    static var controlHit: CGFloat { 28 }
}

/// Play/pause/step/reset controls over a live `CubeEngine` state.
/// Replaces the static case diagram in HUD/Library detail so the same case
/// is not drawn twice. `textOnly` keeps controls and hides the cube.
public struct AlgorithmPlaybackView: View {
    let cubeCase: CubeCase
    let algorithm: String
    let visualMode: VisualMode
    let sizeMode: SizeMode
    var diagramSize: CGSize

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var animator = AlgorithmAnimator()
    @State private var loadError: AlgorithmAnimator.LoadError?

    public init(
        cubeCase: CubeCase,
        algorithm: String,
        visualMode: VisualMode,
        sizeMode: SizeMode,
        diagramSize: CGSize? = nil
    ) {
        self.cubeCase = cubeCase
        self.algorithm = algorithm
        self.visualMode = visualMode
        self.sizeMode = sizeMode
        self.diagramSize = diagramSize ?? PlaybackLayoutMetrics.diagramSize(for: sizeMode)
    }

    private var presentation: PlaybackPresentation {
        PlaybackPresentation(
            visualMode: visualMode,
            loadError: loadError,
            reduceMotion: reduceMotion,
            hasLoadedPlayback: loadError == nil && !animator.notationTokens.isEmpty
        )
    }

    private var notationSize: CGFloat {
        PlaybackLayoutMetrics.notationSize(for: sizeMode)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if presentation.showsDiagram {
                // Gate on successful load. Never pass nil cubeState: CubeStateView
                // would fall back to a valid case-recognition diagram.
                CubeStateView(
                    currentCase: cubeCase,
                    visualMode: visualMode,
                    sizeMode: sizeMode,
                    cubeState: animator.cube
                )
                .frame(width: diagramSize.width, height: diagramSize.height)
                .frame(maxWidth: .infinity)
                .animation(diagramAnimation, value: animator.currentIndex)
                .accessibilityLabel("Cube playback")
            }

            if let errorText = presentation.errorMessage {
                errorBanner(errorText)
            }

            if presentation.showsLiveNotation {
                highlightedMoves
            }

            if presentation.showsTransport {
                transportCluster
                progressRow
                speedRow
            }
        }
        .padding(8)
        .onAppear(perform: reload)
        .onDisappear { animator.stop() }
        .onChange(of: algorithm) { _, _ in
            animator.stop()
            reload()
        }
        .onChange(of: cubeCase.id) { _, _ in
            animator.stop()
            reload()
        }
    }

    private var diagramAnimation: Animation? {
        guard let duration = presentation.diagramAnimationDuration else { return nil }
        return .easeInOut(duration: duration)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.system(size: 13))
            VStack(alignment: .leading, spacing: 4) {
                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
                Text(algorithm)
                    .font(.system(size: notationSize, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityLabel("Playback error: \(message)")
    }

    private var highlightedMoves: some View {
        Text(highlightedAlgorithm)
            .font(.system(size: notationSize, weight: .medium, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
            .accessibilityLabel("Algorithm \(algorithm), current move \(animator.currentMoveNotation ?? "done")")
    }

    private var highlightedAlgorithm: AttributedString {
        var result = AttributedString()
        let tokens = animator.notationTokens
        guard !tokens.isEmpty else {
            return AttributedString(algorithm)
        }
        for (i, token) in tokens.enumerated() {
            var piece = AttributedString(i == tokens.count - 1 ? token : token + " ")
            if i == animator.currentIndex {
                piece.foregroundColor = Color.accentColor
                piece.font = .system(size: notationSize, weight: .bold, design: .monospaced)
            } else if i < animator.currentIndex {
                piece.foregroundColor = Color.secondary
                piece.font = .system(size: notationSize, weight: .medium, design: .monospaced)
            } else {
                piece.foregroundColor = Color.primary
                piece.font = .system(size: notationSize, weight: .medium, design: .monospaced)
            }
            result += piece
        }
        return result
    }

    private var transportCluster: some View {
        HStack(spacing: 8) {
            HStack(spacing: 0) {
                transportButton(
                    systemName: animator.isPlaying ? "pause.fill" : "play.fill",
                    label: animator.isPlaying ? "Pause playback" : "Play playback",
                    disabled: animator.notationTokens.isEmpty || (animator.isFinished && !animator.isPlaying)
                ) {
                    if animator.isPlaying {
                        animator.pause()
                    } else {
                        animator.play()
                    }
                }

                transportButton(
                    systemName: "forward.frame.fill",
                    label: "Step one move",
                    disabled: animator.isFinished || animator.notationTokens.isEmpty
                ) {
                    animator.pause()
                    animator.step()
                }

                transportButton(
                    systemName: "backward.end.fill",
                    label: "Reset playback",
                    disabled: animator.notationTokens.isEmpty
                ) {
                    animator.reset()
                }
            }
            .background(.quaternary, in: Capsule())

            Spacer(minLength: 8)

            Text("\(animator.currentIndex)/\(animator.notationTokens.count)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
    }

    private func transportButton(
        systemName: String,
        label: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: PlaybackLayoutMetrics.controlHit, height: PlaybackLayoutMetrics.controlHit)
                .contentShape(Rectangle())
        }
        .disabled(disabled)
        .foregroundStyle(disabled ? Color.secondary.opacity(0.45) : Color.primary)
        .accessibilityLabel(label)
    }

    private var progressRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Progress")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Move \(animator.currentIndex) of \(animator.notationTokens.count)")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
            ProgressTrack(progress: animator.progress)
                .frame(height: 6)
                .accessibilityLabel("Move \(animator.currentIndex) of \(animator.notationTokens.count)")
        }
    }

    private var speedRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Speed")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(speedLabel)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $animator.speed, in: 0.5...3.0, step: 0.5)
                .controlSize(.small)
                .accessibilityLabel("Playback speed")
        }
    }

    private var speedLabel: String {
        let value = animator.speed
        if value == 0.5 { return "0.5×" }
        if value == 1.0 { return "1×" }
        if value == 1.5 { return "1.5×" }
        if value == 2.0 { return "2×" }
        if value == 2.5 { return "2.5×" }
        if value == 3.0 { return "3×" }
        return String(format: "%.1f×", value)
    }

    private func reload() {
        do {
            try animator.load(algorithm)
            loadError = nil
        } catch let error as AlgorithmAnimator.LoadError {
            loadError = error
        } catch {
            loadError = .emptyAlgorithm
        }
    }
}

private struct ProgressTrack: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(0, geo.size.width * min(1, max(0, progress))))
            }
        }
        .frame(maxWidth: .infinity)
    }
}
