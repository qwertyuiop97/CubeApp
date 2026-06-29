import SwiftUI

public struct StatsView: View {
    @EnvironmentObject private var store: TimeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if store.solves.isEmpty {
                    emptyState
                } else {
                    sessionCard
                    recordsCard
                    lifetimeCard
                    sparklineCard
                }
            }
            .padding(12)
        }
    }

    // MARK: — Empty

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "timer")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundStyle(.tertiary)
            Text("No solves yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Switch to Timer and start solving")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: — Session Card

    private var sessionCard: some View {
        statCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    sectionLabel("Session")
                    Text(store.currentSessionName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(store.solves.count)")
                        .font(.system(size: 28, weight: .light))
                        .monospacedDigit()
                    Text("solves")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }

            if let m = store.meanOfSession {
                cardDivider
                HStack {
                    Text("Session mean")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(format(m))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                }
            }
        }
    }

    // MARK: — Records Card

    private var recordsCard: some View {
        statCard {
            sectionLabel("Records")
            pbRow("PB Single", store.pbSingle)
            cardDivider
            pbRow("Ao5", store.pbAo5)
            cardDivider
            pbRow("Ao12", store.pbAo12)
            cardDivider
            pbRow("Ao100", store.pbAo100)
        }
    }

    private func pbRow(_ label: String, _ value: TimeInterval?) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value.map { format($0) } ?? "—")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(value == nil ? Color.secondary.opacity(0.4) : .primary)
        }
        .padding(.vertical, 1)
    }

    // MARK: — Lifetime Card

    private var lifetimeCard: some View {
        statCard {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(store.lifetimeSolveCount)")
                        .font(.system(size: 28, weight: .light))
                        .monospacedDigit()
                    Text("lifetime solves")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .bottom, spacing: 3) {
                        Text("\(store.dailyStreak)")
                            .font(.system(size: 28, weight: .light))
                            .monospacedDigit()
                        Text("🔥")
                            .font(.system(size: 16))
                            .padding(.bottom, 3)
                    }
                    Text("day streak")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: — Sparkline Card

    private var sparklineCard: some View {
        statCard {
            sectionLabel("Last 12 solves")
            sparkline
                .frame(height: 60)
        }
    }

    private var sparkline: some View {
        GeometryReader { geo in
            let recent = Array(store.solves.prefix(12).reversed())
            let valid = recent.filter { $0.penalty != .dnf }
            if valid.isEmpty { return AnyView(EmptyView()) }
            let times = valid.map { $0.time }
            let minT = times.min() ?? 0
            let maxT = times.max() ?? 1
            let range = max(maxT - minT, 0.001)
            let w = geo.size.width
            let h = geo.size.height
            let step = w / CGFloat(max(recent.count - 1, 1))

            func point(for rec: SolveRecord, at i: Int) -> CGPoint? {
                guard rec.penalty != .dnf else { return nil }
                let x = CGFloat(i) * step
                let norm = (rec.time - minT) / range
                let y = h - CGFloat(norm) * (h - 8) - 4
                return CGPoint(x: x, y: y)
            }

            return AnyView(
                ZStack {
                    // Line
                    Path { p in
                        var moved = false
                        for (i, rec) in recent.enumerated() {
                            guard let pt = point(for: rec, at: i) else { continue }
                            if !moved { p.move(to: pt); moved = true }
                            else { p.addLine(to: pt) }
                        }
                    }
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

                    // Dots & DNF markers
                    ForEach(Array(recent.enumerated()), id: \.offset) { i, rec in
                        if rec.penalty == .dnf {
                            Circle()
                                .fill(Color.red.opacity(0.6))
                                .frame(width: 5, height: 5)
                                .position(x: CGFloat(i) * step, y: 8)
                        } else if let pt = point(for: rec, at: i) {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 5, height: 5)
                                .position(x: pt.x, y: pt.y)
                        }
                    }
                }
            )
        }
    }

    // MARK: — Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(.tertiary)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    private var cardDivider: some View {
        Divider().opacity(0.1)
    }

    private func statCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }

    private func format(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = t.truncatingRemainder(dividingBy: 60)
        return m > 0 ? String(format: "%d:%05.2f", m, s) : String(format: "%.2f", s)
    }
}
