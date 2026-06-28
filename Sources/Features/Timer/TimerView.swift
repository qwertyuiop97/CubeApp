import SwiftUI

public struct TimerView: View {
    @EnvironmentObject private var timer: SolveTimer
    @EnvironmentObject private var store: TimeStore

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
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 6)

            Text(timer.formattedTime)
                .font(.system(size: 38, weight: .semibold, design: .monospaced))
                .monospacedDigit()
                .padding(.vertical, 8)

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
                } else {
                    Button(timer.state == .stopped ? "Reset" : "Start") {
                        timer.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                Button("New Session") {
                    store.clearSession()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            // Stats
            HStack(spacing: 12) {
                stat("ao5", store.ao5)
                stat("ao12", store.ao12)
                stat("ao100", store.ao100)
            }
            .font(.caption)

            // Recent solves
            if !store.solves.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(store.solves.prefix(10)) { rec in
                            HStack {
                                Text(formatTime(rec.time))
                                    .font(.system(.caption, design: .monospaced))
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
