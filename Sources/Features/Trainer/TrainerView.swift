import SwiftUI
import AppKit

public struct TrainerView: View {
    @EnvironmentObject private var store: TrainerStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var filter: String = "Both"
    @State private var currentCase: CubeCase? = nil
    @State private var isRevealed = false
    @State private var lastResult: Bool? = nil

    private var pool: [CubeCase] {
        let all = AlgorithmDatabase.ollCases + AlgorithmDatabase.pllCases
        switch filter {
        case "OLL": return all.filter { $0.caseType == "OLL" }
        case "PLL": return all.filter { $0.caseType == "PLL" }
        default: return all
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            filterBar
            Spacer(minLength: 0)
            if let c = currentCase {
                diagramSection(c)
                Spacer(minLength: 0)
                if isRevealed {
                    revealedSection(c)
                } else {
                    hiddenSection
                }
            } else {
                emptyState
            }
            Spacer(minLength: 0)
            nextButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear {
            if currentCase == nil { pickNewCase() }
        }
    }

    // MARK: — Filter Bar

    private var filterBar: some View {
        Group {
            if #available(macOS 26.0, *) {
                GlassEffectContainer(spacing: 8) { filterPicker }
            } else {
                filterPicker
            }
        }
        .padding(.bottom, 8)
    }

    private var filterPicker: some View {
        Picker("", selection: $filter) {
            Text("Both").tag("Both")
            Text("OLL").tag("OLL")
            Text("PLL").tag("PLL")
        }
        .pickerStyle(.segmented)
        .frame(width: 160)
        .cubeNotchGlass(cornerRadius: 8)
        .onChange(of: filter) { _, _ in pickNewCase() }
    }

    // MARK: — Diagram

    private func diagramSection(_ c: CubeCase) -> some View {
        VStack(spacing: 6) {
            CubeStateView(currentCase: c, visualMode: .preExecution, sizeMode: .large)
                .frame(width: 200, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )

            accuracyBadge(for: c)
        }
    }

    private func accuracyBadge(for c: CubeCase) -> some View {
        let stats = store.stats(for: c.id)
        let acc = store.accuracy(for: c.id)
        return Group {
            if stats.attemptCount > 0 {
                HStack(spacing: 4) {
                    Circle()
                        .fill(accuracyColor(acc))
                        .frame(width: 6, height: 6)
                    Text(String(format: "%.0f%% · %d attempts", acc * 100, stats.attemptCount))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func accuracyColor(_ acc: Double) -> Color {
        acc >= 0.8 ? .green : (acc >= 0.5 ? .orange : .red)
    }

    // MARK: — Hidden (before reveal)

    private var hiddenSection: some View {
        Button("Reveal") {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
                isRevealed = true
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
        .cubeNotchGlass(cornerRadius: 8)
    }

    // MARK: — Revealed

    private func revealedSection(_ c: CubeCase) -> some View {
        VStack(spacing: 10) {
            VStack(spacing: 4) {
                Text("\(c.caseType) \(c.caseNumber) — \(c.name)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))

                Text(c.primaryAlgorithm)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))

            if let result = lastResult {
                resultBadge(result)
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
            }

            Group {
                if #available(macOS 26.0, *) {
                    GlassEffectContainer(spacing: 12) { judgeButtons }
                } else {
                    judgeButtons
                }
            }
            .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var judgeButtons: some View {
        HStack(spacing: 12) {
            Button {
                recordResult(correct: true)
            } label: {
                Label("Got it", systemImage: "checkmark")
                    .frame(minWidth: 72)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.regular)
            .cubeNotchGlass(cornerRadius: 8)

            Button {
                recordResult(correct: false)
            } label: {
                Label("Missed", systemImage: "xmark")
                    .frame(minWidth: 72)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .cubeNotchGlass(cornerRadius: 8)
        }
    }

    private func resultBadge(_ correct: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(correct ? .green : .red)
            Text(correct ? "Correct" : "Missed")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(correct ? .green : .red)
        }
        .font(.system(size: 13))
    }

    // MARK: — Empty

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "brain")
                .font(.system(size: 28, weight: .ultraLight))
                .foregroundStyle(.tertiary)
            Text("Tap Next Case to begin")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: — Next Button

    private var nextButton: some View {
        Button("Next Case") {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                pickNewCase()
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .cubeNotchGlass(cornerRadius: 6)
        .padding(.top, 8)
    }

    // MARK: — Logic

    private func pickNewCase() {
        currentCase = store.randomCase(from: pool)
        isRevealed = false
        lastResult = nil
    }

    private func recordResult(correct: Bool) {
        guard let c = currentCase else { return }
        store.recordAttempt(for: c.id, correct: correct)
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) {
            lastResult = correct
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                pickNewCase()
            }
        }
    }
}
