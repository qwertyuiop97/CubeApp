import Foundation
import SwiftUI

public struct SolveRecord: Identifiable, Codable, Equatable {
    public let id: UUID
    public let time: TimeInterval
    public let scramble: String
    public let date: Date

    public init(time: TimeInterval, scramble: String, date: Date = Date()) {
        self.id = UUID()
        self.time = time
        self.scramble = scramble
        self.date = date
    }
}

public final class TimeStore: ObservableObject {
    @Published public private(set) var solves: [SolveRecord] = []

    private let storageKey = "cubeNotchTimeSolves"

    public init() {
        load()
    }

    public func addSolve(time: TimeInterval, scramble: String) {
        let record = SolveRecord(time: time, scramble: scramble)
        solves.insert(record, at: 0)
        save()
    }

    public func clearSession() {
        solves.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    // Simple means for Phase 6C (can be enhanced to trimmed means later)
    public var ao5: TimeInterval? { meanOfLast(5) }
    public var ao12: TimeInterval? { meanOfLast(12) }
    public var ao100: TimeInterval? { meanOfLast(100) }

    public var bestTime: TimeInterval? {
        solves.map { $0.time }.min()
    }

    private func meanOfLast(_ n: Int) -> TimeInterval? {
        let recent = Array(solves.prefix(n))
        guard recent.count >= 1 else { return nil }
        let sum = recent.reduce(0) { $0 + $1.time }
        return sum / Double(recent.count)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(solves) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([SolveRecord].self, from: data) else {
            solves = []
            return
        }
        solves = decoded
    }
}
