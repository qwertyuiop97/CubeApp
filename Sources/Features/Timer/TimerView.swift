import SwiftUI

public struct TimerView: View {
    @EnvironmentObject private var timer: SolveTimer
    @EnvironmentObject private var store: TimeStore
    @State private var showNewPB = false
    @State private var newPBText = ""

    public var body: some View {
        VStack(spacing: 8) {
            Text("Scramble")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(timer.scramble)
                .font(.system(size: 14, design: .monospaced))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 6)

            Text(timer.formattedTime)
                .font(.system(size: 72, weight: .light))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.08), value: timer.formattedTime)
                .padding(.vertical, 8)
                .foregroundColor(timer.isRunning ? .primary : (timer.state == .stopped ? .orange : .green))

            HStack(spacing: 10) {
                Button("New") {
                    timer.newScramble()
                    timer.reset()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

            if timer.isRunning {
                Button("Stop") {
                    timer.stop()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .cubeNotchGlass(cornerRadius: 6)
            } else {
                Button(timer.state == .stopped ? "Reset" : "Start") {
                    timer.toggle()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .cubeNotchGlass(cornerRadius: 6)
            }

            // 15A-2 +2 / DNF also get glass
            if timer.state == .stopped {
                HStack(spacing: 8) {
                    Button("+2") {
                        timer.applyPenalty(.plusTwo)
                        store.updateLastSolve(addPenalty: .plusTwo)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .cubeNotchGlass(cornerRadius: 6)

                    Button("DNF") {
                        timer.applyPenalty(.dnf)
                        store.updateLastSolve(addPenalty: .dnf)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .cubeNotchGlass(cornerRadius: 6)
                }
            }

            Button("New Session") {
                store.clearSession()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            // 14A-1 Export
            Button("Export CSV") {
                if let url = store.saveCSVToDesktop() {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(url.path, forType: .string)
                }
            }
            .font(.caption2)
            .buttonStyle(.plain)

            Toggle("Cross Practice", isOn: $timer.isCrossPractice)
                .font(.caption)
                .onChange(of: timer.isCrossPractice) { _, newValue in
                    if !timer.isRunning {
                        timer.newScramble()
                        timer.reset()
                    }
                }

            if timer.isCrossPractice {
                Text("Cross solves this session: \(timer.crossSolveCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Stats + PBs (16A-1)
            HStack(spacing: 12) {
                stat("ao5", store.ao5)
                stat("ao12", store.ao12)
                stat("ao100", store.ao100)
                if let best = store.bestTime {
                    Text("Best: \(formatTime(best))").font(.caption)
                }
            }
            .font(.system(size: 20))
            .monospacedDigit()

            if let pb = store.pbSingle {
                Text("PB: \(formatTime(pb))")
                    .font(.caption.bold())
                    .foregroundStyle(.yellow)
            }
        }
        .font(.caption)

        if showNewPB {
            Text(newPBText)
                .font(.caption.bold())
                .foregroundStyle(.yellow)
                .transition(.opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showNewPB = false }
                    }
                }
        }

            // Recent solves
            if !store.solves.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(store.solves.prefix(10)) { rec in
                            HStack {
                                if rec.penalty == .dnf {
                                    Text("DNF")
                                        .font(.system(.caption, design: .monospaced))
                                } else {
                                    let shown = rec.penalty == .plusTwo ? rec.time + 2.0 : rec.time
                                    Text(formatTime(shown))
                                        .font(.system(.caption, design: .monospaced))
                                }
                                Text(rec.scramble.prefix(28) + (rec.scramble.count > 28 ? "…" : ""))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
                .frame(maxHeight: 80)
            } else {
                Text("No solves yet")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text("Spacebar starts / stops")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .onAppear { timer.isTimerTabActive = true }
        .onDisappear { timer.isTimerTabActive = false }

        // 16A-1: New PB banner
        if showNewPB {
            Text(newPBText)
                .font(.caption.bold())
                .foregroundStyle(.yellow)
                .transition(.opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showNewPB = false }
                    }
                }
        }
    }

    private func stat(_ label: String, _ value: TimeInterval?) -> some View {
        let s = value.map { formatTime($0) } ?? "—"
        return VStack(spacing: 1) {
            Text(label).foregroundStyle(.secondary)
            Text(s).font(.system(.caption, design: .monospaced))
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = t.truncatingRemainder(dividingBy: 60)
        if m > 0 { return String(format: "%d:%05.2f", m, s) }
        return String(format: "%.2f", s)
    }
}
