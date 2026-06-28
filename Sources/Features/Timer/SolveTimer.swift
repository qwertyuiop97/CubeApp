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
        scramble = ScrambleGenerator.generate3x3()
    }

    public func start() {
        guard state != .running else { return }
        startTime = Date()
        finalTime = nil
        displayElapsed = 0
        state = .running
        startUpdateTimer()
    }

    public var onSolveFinished: ((TimeInterval, String) -> Void)?

    public func stop() {
        guard state == .running else { return }
        finalTime = Date().timeIntervalSince(startTime ?? Date())
        state = .stopped
        stopUpdateTimer()
        if let t = finalTime {
            onSolveFinished?(t, scramble)
        }
    }

    public func reset() {
        stopUpdateTimer()
        state = .idle
        startTime = nil
        finalTime = nil
        displayElapsed = 0
    }

    public func toggle() {
        if state == .running {
            stop()
        } else {
            if state == .stopped {
                reset()
            }
            start()
        }
    }

    private func startUpdateTimer() {
        stopUpdateTimer()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self = self, self.state == .running else { return }
            self.displayElapsed = self.elapsed
        }
    }

    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}
