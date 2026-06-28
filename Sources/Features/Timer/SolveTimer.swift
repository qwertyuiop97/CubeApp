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

    // 17A-2 Inspection
    @Published public var isInspecting: Bool = false
    @Published public var inspectionRemaining: TimeInterval = 15.0

    public private(set) var startTime: Date?
    public private(set) var finalTime: TimeInterval?

    private var updateTimer: Timer?
    private var inspectionTimer: Timer?
    private var pendingPenalty: Penalty = .none

    private var wcaInspectionEnabled: Bool {
        UserDefaults.standard.object(forKey: UDKey.wcaInspection) as? Bool ?? true
    }

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
        if isInspecting {
            // space during inspection starts solve; apply any auto penalty
            let pen = pendingInspectionPenalty()
            lastSolvePenalty = pen
            stopInspection()
            // start fresh solve (inspection done)
            reset()
            start()
        } else if state == .running {
            stop()
            // after stop, if WCA inspection on, begin countdown
            if wcaInspectionEnabled {
                DispatchQueue.main.async { self.startInspection() }
            }
        } else if state == .stopped {
            if wcaInspectionEnabled {
                startInspection()
            } else {
                reset()
                start()
            }
        } else {
            start()
        }
    }

    private func startInspection() {
        isInspecting = true
        inspectionRemaining = 15.0
        pendingPenalty = .none
        state = .idle
        startInspectionTimer()
    }

    private func startInspectionTimer() {
        stopInspectionTimer()
        let t = Timer(timeInterval: 1.0/10.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isInspecting else { return }
            self.inspectionRemaining -= 0.1
            if self.inspectionRemaining <= -2.0 {
                self.pendingPenalty = .dnf
                self.stopInspection()
                // auto DNF without starting solve
                self.state = .stopped
                self.finalTime = -1
                self.lastSolvePenalty = .dnf
                if let t = self.finalTime {
                    self.onSolveFinished?(t, self.scramble, .dnf)
                }
            } else if self.inspectionRemaining <= 0 {
                self.pendingPenalty = .plusTwo
            }
        }
        RunLoop.main.add(t, forMode: .common)
        inspectionTimer = t
    }

    private func stopInspectionTimer() {
        inspectionTimer?.invalidate()
        inspectionTimer = nil
    }

    public func stopInspection() {
        stopInspectionTimer()
        isInspecting = false
    }

    private func pendingInspectionPenalty() -> Penalty {
        if inspectionRemaining <= -2 { return .dnf }
        if inspectionRemaining <= 0 { return .plusTwo }
        return .none
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
