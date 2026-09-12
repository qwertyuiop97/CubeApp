import SwiftUI

public struct TimerView: View {
    @EnvironmentObject private var timer: SolveTimer
    @EnvironmentObject private var store: TimeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingNewSession = false
    @State private var newSessionName = ""
    @State private var exportDone = false

    public var body: some View {
        VStack(spacing: 0) {
            scrambleHeader
            timerHero
            statsStrip
            Divider().opacity(0.1)
            solveHistory
            bottomBar
        }
        .onAppear { timer.isTimerTabActive = true }
        .onDisappear { timer.isTimerTabActive = false }
    }

    // MARK: — Scramble

    private var scrambleHeader: some View {
        Text(timer.scramble)
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 2)
    }

    // MARK: — Timer Hero

    private var timerHero: some View {
        VStack(spacing: 6) {
            if timer.isInspecting {
                let rem = max(0.0, timer.inspectionRemaining)
                Text(String(format: "%.0f", rem))
                    .font(.system(size: 72, weight: .ultraLight))
                    .monospacedDigit()
                    .foregroundStyle(rem < 5 ? Color.orange : .primary)
            } else {
                Text(timer.formattedTime)
                    .font(.system(size: 72, weight: .ultraLight))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.08), value: timer.formattedTime)
                    .foregroundStyle(timer.isArmed ? Color.green : .primary)
            }

            stateHint

            if let pb = store.newPBMessage {
                Text(pb)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.12), in: Capsule())
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
            }

            timerControls
        }
        .padding(.vertical, 8)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: store.newPBMessage)
    }

    private var stateHint: some View {
        Group {
            if timer.isInspecting {
                Text("Inspection")
            } else if timer.isArmed {
                Text("Release to start")
                    .foregroundStyle(.green)
            } else if timer.isRunning {
                Text("Space to stop")
            } else if timer.state == .stopped {
                Text("Stopped")
            } else {
                Text("Hold Space")
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(.tertiary)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: timer.isArmed)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: timer.state.rawValue)
    }

    @ViewBuilder
    private var timerControls: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: 8) { controlButtons }
        } else {
            controlButtons
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 8) {
            Button {
                timer.newScramble()
                timer.reset()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .cubeNotchGlass(cornerRadius: 8)
            .help("New scramble")
            .disabled(timer.isRunning)

            if timer.state == .stopped {
                Button("+2") {
                    TimerPenaltyControls.apply(.plusTwo, timer: timer, store: store)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .cubeNotchGlass(cornerRadius: 6)

                Button("DNF") {
                    TimerPenaltyControls.apply(.dnf, timer: timer, store: store)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .cubeNotchGlass(cornerRadius: 6)

                Button {
                    timer.reset()
                } label: {
                    Image(systemName: "xmark.circle")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .cubeNotchGlass(cornerRadius: 8)
                .help("Reset")
            }
        }
        .padding(.top, 4)
    }

    // MARK: — Stats Strip

    private var statsStrip: some View {
        HStack(spacing: 0) {
            statCell("AO5", store.ao5)
            stripDivider
            statCell("AO12", store.ao12)
            stripDivider
            statCell("AO100", store.ao100)
            stripDivider
            statCell("BEST", store.bestTime)
        }
        .padding(.vertical, 10)
    }

    private var stripDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 1, height: 24)
    }

    private func statCell(_ label: String, _ value: TimeInterval?) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .tracking(0.5)
            Text(value.map { formatTime($0) } ?? "—")
                .font(.system(size: 14, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(value == nil ? Color.secondary.opacity(0.4) : .primary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: — Solve History

    private var solveHistory: some View {
        ScrollView {
            VStack(spacing: 0) {
                if store.solves.isEmpty {
                    Text("No solves yet")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else {
                    ForEach(Array(store.solves.prefix(12).enumerated()), id: \.offset) { idx, rec in
                        HStack(spacing: 6) {
                            Text("\(idx + 1)")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.secondary.opacity(0.35))
                                .frame(width: 14, alignment: .trailing)

                            Group {
                                if rec.penalty == .dnf {
                                    Text("DNF")
                                        .foregroundStyle(.red)
                                } else {
                                    HStack(spacing: 2) {
                                        let t = rec.penalty == .plusTwo ? rec.time + 2 : rec.time
                                        Text(formatTime(t))
                                        if rec.penalty == .plusTwo {
                                            Text("+2")
                                                .font(.system(size: 9))
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                }
                            }
                            .font(.system(size: 12, weight: .medium, design: .monospaced))

                            Text(rec.scramble.prefix(22) + (rec.scramble.count > 22 ? "…" : ""))
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 3)
                        .background(idx % 2 == 1 ? Color.white.opacity(0.025) : Color.clear)
                    }
                }
            }
        }
        .frame(maxHeight: 90)
    }

    // MARK: — Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 0) {
            Toggle("", isOn: $timer.isCrossPractice)
                .toggleStyle(.checkbox)
                .onChange(of: timer.isCrossPractice) { _, _ in
                    if !timer.isRunning { timer.newScramble(); timer.reset() }
                }
            Text(timer.isCrossPractice ? "Cross (\(timer.crossSolveCount))" : "Cross")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            Spacer()

            Text(store.currentSessionName)
                .font(.system(size: 10))
                .foregroundStyle(Color.secondary.opacity(0.5))
                .lineLimit(1)
                .frame(maxWidth: 80)

            Spacer()

            HStack(spacing: 12) {
                Button("New Session") {
                    newSessionName = ""
                    showingNewSession = true
                }
                .font(.system(size: 11))
                .buttonStyle(.plain)
                .foregroundStyle(Color.secondary.opacity(0.6))
                .popover(isPresented: $showingNewSession) {
                    VStack(spacing: 8) {
                        Text("New session")
                            .font(.caption.weight(.medium))
                        TextField("Name (optional)", text: $newSessionName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 160)
                        Button("Create") {
                            let name = newSessionName.trimmingCharacters(in: .whitespaces)
                            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
                            store.startNewNamedSession(name: name.isEmpty ? df.string(from: Date()) : name)
                            showingNewSession = false
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(12)
                }

                Button(exportDone ? "✓" : "Export") {
                    if store.saveCSVToDesktop() != nil {
                        exportDone = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { exportDone = false }
                    }
                }
                .font(.system(size: 11))
                .buttonStyle(.plain)
                .foregroundStyle(exportDone ? Color.green : Color.secondary.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.03))
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = t.truncatingRemainder(dividingBy: 60)
        return m > 0 ? String(format: "%d:%05.2f", m, s) : String(format: "%.2f", s)
    }
}

/// Shared stopped-solve penalty path so the hero display and stored record stay aligned.
public enum TimerPenaltyControls {
    public static func apply(_ penalty: Penalty, timer: SolveTimer, store: TimeStore) {
        timer.applyPenalty(penalty)
        store.updateLastSolve(addPenalty: penalty)
    }
}
