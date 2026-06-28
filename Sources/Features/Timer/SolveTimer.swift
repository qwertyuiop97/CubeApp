import Foundation
import SwiftUI
import Combine

public enum TimerState: String, CaseIterable, Codable {
    case idle
    case running
    case stopped
}

public final class SolveTimer: ObservableObject {
    @Published public var state: TimerState = .idle
    @Published public var scramble: String = ""
    @Published public var isTimerTabActive: Bool = false
    @Published public var displayElapsed: TimeInterval = 0
    @Published public var isCrossPractice: Bool = false
    @Published public var crossSolveCount: Int = 0
    @Published public var lastSolvePenalty: Penalty = .none

    public private(set) var startTime: Date?
    public private(set) var finalTime: TimeInterval?

    private var updateTimer: Timer?

    public init() {
        newScramble()
    }

    public var elapsed: TimeInterval {
        if state == .running, let start = startTime {
            return Date().timeIntervalSince(start)
        } else if let final = finalTime {
            return final
        }
        return 0
    }

    public var formattedTime: String {
        let t = (state == .running ? displayElapsed : (finalTime ?? 0))
        let minutes = Int(t) / 60
        let seconds = t.truncatingRemainder(dividingBy: 60)
        if minutes > 0 {
            return String(format: "%d:%05.2f", minutes, seconds)
        } else {
            return String(format: "%.2f", seconds)
        }
    }

    public var isRunning: Bool { state == .running }

    public func newScramble() {
        if isCrossPractice {
            scramble = ScrambleGenerator.generateCrossPractice()
        } else {
            scramble = ScrambleGenerator.generate3x3()
        }
    }

    public func start() {
        guard state != .running else { return }
        startTime = Date()
        finalTime = nil
        displayElapsed = 0
        state = .running
        startUpdateTimer()
    }

    public var onSolveFinished: ((TimeInterval, String, Penalty) -> Void)?

    public func stop() {
        guard state == .running else { return }
        finalTime = Date().timeIntervalSince(startTime ?? Date())
        state = .stopped
        stopUpdateTimer()
        if let t = finalTime {
            onSolveFinished?(t, scramble, lastSolvePenalty)
            if isCrossPractice {
                incrementCrossCount()
            }
        }
    }

    public func reset() {
        stopUpdateTimer()
        state = .idle
        startTime = nil
        finalTime = nil
        displayElapsed = 0
        lastSolvePenalty = .none
    }

    public func incrementCrossCount() {
        if isCrossPractice {
            crossSolveCount += 1
        }
    }

    public func applyPenalty(_ penalty: Penalty) {
        guard state == .stopped, let current = finalTime else { return }
        lastSolvePenalty = penalty
        switch penalty {
        case .plusTwo:
            finalTime = current + 2.0
        case .dnf:
            finalTime = -1
        case .none:
            break
        }
    }

    public func toggle() {
        if state == .running {
            stop()
        } else if state == .stopped {
            // Single spacebar from stopped: immediately start a fresh solve
            reset()
            start()
        } else {
            start()
        }
    }

    private func startUpdateTimer() {
        stopUpdateTimer()
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self = self, self.state == .running else { return }
            self.displayElapsed = self.elapsed
        }
        RunLoop.main.add(t, forMode: .common)
        updateTimer = t
    }

    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}
