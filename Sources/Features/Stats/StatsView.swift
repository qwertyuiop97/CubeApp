import SwiftUI

public struct StatsView: View {
    @EnvironmentObject private var store: TimeStore

    public var body: some View {
        VStack(spacing: 12) {
            Text("Personal Bests")
                .font(.headline)

            VStack(spacing: 6) {
                pbRow("Single", store.pbSingle ?? store.bestTime)
                pbRow("Ao5", store.pbAo5 ?? store.ao5)
                pbRow("Ao12", store.pbAo12 ?? store.ao12)
                pbRow("Ao100", store.pbAo100 ?? store.ao100)
            }

            Divider()

            Text("Solves this session: \(store.solves.count)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let best = store.bestTime {
                Text("Session best: \(format(best))")
                    .font(.caption)
            }
        }
        .padding()
    }

    private func pbRow(_ label: String, _ value: TimeInterval?) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value.map { format($0) } ?? "—")
                .font(.system(.body, design: .monospaced))
        }
    }

    private func format(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = t.truncatingRemainder(dividingBy: 60)
        return m > 0 ? String(format: "%d:%05.2f", m, s) : String(format: "%.2f", s)
    }
}
