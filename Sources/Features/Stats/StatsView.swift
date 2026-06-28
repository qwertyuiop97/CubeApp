import SwiftUI

public struct StatsView: View {
    @EnvironmentObject private var store: TimeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public var body: some View {
        VStack(spacing: 12) {
            if store.solves.isEmpty {
                Text("No solves yet — start the timer!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                Text("Session")
                    .font(.headline)

                HStack(spacing: 16) {
                    Text("Solves: \(store.solves.count)")
                    if let m = store.meanOfSession {
                        Text("Mean: \(format(m))")
                    }
                }
                .font(.caption)

                if let msg = store.newPBMessage {
                    Text(msg)
                        .font(.caption.bold())
                        .foregroundStyle(.yellow)
                        .transition(.opacity)
                }

                Divider()

                Text("Records")
                    .font(.headline)

                VStack(spacing: 4) {
                    pbRow("Single", store.pbSingle)
                    pbRow("Ao5", store.pbAo5)
                    pbRow("Ao12", store.pbAo12)
                }

                Divider()

                Text("Lifetime solves: \(store.lifetimeSolveCount)")
                    .font(.caption2)

                Text("Daily streak: \(store.dailyStreak)")
                    .font(.caption2)

                Divider()

                sparkline
                    .frame(height: 60)
                    .padding(.horizontal, 8)
            }
        }
        .padding(8)
    }

    private func pbRow(_ label: String, _ value: TimeInterval?) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value.map { format($0) } ?? "—")
                .font(.system(.caption, design: .monospaced))
        }
    }

    private var sparkline: some View {
        GeometryReader { geo in
            let recent = Array(store.solves.prefix(12).reversed())
            let valid = recent.filter { $0.penalty != .dnf }
            guard !valid.isEmpty else { return AnyView(EmptyView()) }
            let times = valid.map { $0.time }
            let minT = times.min() ?? 0
            let maxT = times.max() ?? 1
            let w = geo.size.width
            let h = geo.size.height
            let step = w / CGFloat(max(recent.count - 1, 1))

            return AnyView(
                ZStack {
                    Path { p in
                        for (i, rec) in recent.enumerated() {
                            if rec.penalty == .dnf { continue }
                            let x = CGFloat(i) * step
                            let norm = (rec.time - minT) / max((maxT - minT), 0.001)
                            let y = h - CGFloat(norm) * (h - 4) - 2
                            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                            else { p.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(Color.accentColor, lineWidth: 1.5)

                    ForEach(Array(recent.enumerated()), id: \.offset) { i, rec in
                        let x = CGFloat(i) * step
                        if rec.penalty == .dnf {
                            Text("✕")
                                .font(.caption2)
                                .foregroundStyle(.red)
                                .position(x: x, y: 6)
                        } else {
                            let norm = (rec.time - minT) / max((maxT - minT), 0.001)
                            let y = h - CGFloat(norm) * (h - 4) - 2
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 4, height: 4)
                                .position(x: x, y: y)
                        }
                    }
                }
            )
        }
    }

    private func format(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = t.truncatingRemainder(dividingBy: 60)
        return m > 0 ? String(format: "%d:%05.2f", m, s) : String(format: "%.2f", s)
    }
}
