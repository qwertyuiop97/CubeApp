import SwiftUI
import AppKit

public struct TrainerView: View {
    @EnvironmentObject private var store: TrainerStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var filter: String = "Both" // OLL | PLL | Both
    @State private var currentCase: CubeCase? = nil
    @State private var isRevealed = false
    @State private var accuracyText: String = ""

    private var pool: [CubeCase] {
        let all = AlgorithmDatabase.ollCases + AlgorithmDatabase.pllCases
        switch filter {
        case "OLL": return all.filter { $0.caseType == "OLL" }
        case "PLL": return all.filter { $0.caseType == "PLL" }
        default: return all
        }
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Filter
            Group {
                if #available(macOS 26.0, *) {
                    GlassEffectContainer(spacing: 8) {
                        Picker("Show", selection: $filter) {
                            Text("Both").tag("Both")
                            Text("OLL").tag("OLL")
                            Text("PLL").tag("PLL")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                        .cubeNotchGlass(cornerRadius: 8)
                    }
                } else {
                    Picker("Show", selection: $filter) {
                        Text("Both").tag("Both")
                        Text("OLL").tag("OLL")
                        Text("PLL").tag("PLL")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                    .cubeNotchGlass(cornerRadius: 8)
                }
            }
            .onChange(of: filter) { _, _ in
                pickNewCase()
            }

            // Diagram
            if let c = currentCase {
                CubeStateView(currentCase: c, visualMode: .preExecution, sizeMode: .large)
                    .frame(width: 220, height: 180)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                if isRevealed {
                    VStack(spacing: 4) {
                        Text("\(c.caseType) \(c.caseNumber) — \(c.name)")
                            .font(.headline)
                        Text(c.primaryAlgorithm)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .padding(.top, 4)

                    if !accuracyText.isEmpty {
                        Text(accuracyText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Group {
                        if #available(macOS 26.0, *) {
                            GlassEffectContainer(spacing: 8) {
                                HStack(spacing: 12) {
                                    Button("Got it ✓") {
                                        recordResult(correct: true)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .cubeNotchGlass(cornerRadius: 6)

                                    Button("Missed ✗") {
                                        recordResult(correct: false)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .cubeNotchGlass(cornerRadius: 6)
                                }
                            }
                        } else {
                            HStack(spacing: 12) {
                                Button("Got it ✓") {
                                    recordResult(correct: true)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .cubeNotchGlass(cornerRadius: 6)

                                Button("Missed ✗") {
                                    recordResult(correct: false)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .cubeNotchGlass(cornerRadius: 6)
                            }
                        }
                    }
                } else {
                    Button("Reveal") {
                        if reduceMotion {
                            isRevealed = true
                            updateAccuracyText(for: c)
                        } else {
                            withAnimation {
                                isRevealed = true
                                updateAccuracyText(for: c)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            } else {
                Text("Tap to start training")
                    .foregroundStyle(.secondary)
            }

            Button("Next Case") {
                pickNewCase()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .padding(.top, 4)
        }
        .padding()
        .onAppear {
            if currentCase == nil {
                pickNewCase()
            }
        }
    }

    private func pickNewCase() {
        currentCase = store.randomCase(from: pool)
        isRevealed = false
        accuracyText = ""
    }

    private func recordResult(correct: Bool) {
        guard let c = currentCase else { return }
        store.recordAttempt(for: c.id, correct: correct)
        updateAccuracyText(for: c)
        // auto-advance after feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            pickNewCase()
        }
    }

    private func updateAccuracyText(for c: CubeCase) {
        let acc = store.accuracy(for: c.id)
        accuracyText = String(format: "Accuracy: %.0f%% (%d attempts)", acc * 100, store.stats(for: c.id).attemptCount)
    }
}
