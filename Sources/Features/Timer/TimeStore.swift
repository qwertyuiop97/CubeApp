import Foundation
import SwiftUI

public enum Penalty: String, Codable, Equatable {
    case none
    case plusTwo
    case dnf
}

public struct SolveRecord: Identifiable, Codable, Equatable {
    public let id: UUID
    public var time: TimeInterval
    public let scramble: String
    public let date: Date
    public var penalty: Penalty

    public init(time: TimeInterval, scramble: String, date: Date = Date(), penalty: Penalty = .none) {
        self.id = UUID()
        self.time = time
        self.scramble = scramble
        self.date = date
        self.penalty = penalty
    }

    private enum CodingKeys: String, CodingKey {
        case id, time, scramble, date, penalty
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        time = try container.decode(TimeInterval.self, forKey: .time)
        scramble = try container.decode(String.self, forKey: .scramble)
        date = try container.decode(Date.self, forKey: .date)
        penalty = try container.decodeIfPresent(Penalty.self, forKey: .penalty) ?? .none
    }
}

public final class TimeStore: ObservableObject {
    @Published public private(set) var solves: [SolveRecord] = []

    private let storageKey = "cubeNotchTimeSolves"

    public init() {
        load()
    }

    public func addSolve(time: TimeInterval, scramble: String, penalty: Penalty = .none) {
        let record = SolveRecord(time: time, scramble: scramble, penalty: penalty)
        solves.insert(record, at: 0)
        save()
    }

    public func clearSession() {
        solves.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    // ao5/ao12/ao100 use WCA trimmed mean (discard best + worst when >=5/12/100)
    public var ao5: TimeInterval? { trimmedMean(count: 5, trim: 1) }
    public var ao12: TimeInterval? { trimmedMean(count: 12, trim: 1) }
    public var ao100: TimeInterval? { trimmedMean(count: 100, trim: 1) }

    public var bestTime: TimeInterval? {
        solves.filter { $0.penalty != .dnf }.map { effectiveTime($0) }.min()
    }

    public func updateLastSolve(addPenalty: Penalty) {
        guard var first = solves.first else { return }
        switch addPenalty {
        case .plusTwo:
            if first.penalty == .plusTwo { first.time -= 2.0; first.penalty = .none }
            else if first.penalty != .dnf { first.time += 2.0; first.penalty = .plusTwo }
        case .dnf:
            first.penalty = .dnf
        case .none:
            if first.penalty == .plusTwo { first.time -= 2.0 }
            first.penalty = .none
        }
        solves[0] = first
        save()
    }

    private func effectiveTime(_ rec: SolveRecord) -> TimeInterval {
        switch rec.penalty {
        case .dnf: return .greatestFiniteMagnitude
        case .plusTwo: return rec.time + 2.0
        case .none: return rec.time
        }
    }

    private func trimmedMean(count: Int, trim: Int) -> TimeInterval? {
        let valid = solves.filter { $0.penalty != .dnf }
        guard valid.count >= count else { return nil }
        let times = Array(valid.prefix(count).map { effectiveTime($0) }.sorted())
        let trimmed = Array(times.dropFirst(trim).dropLast(trim))
        guard !trimmed.isEmpty else { return nil }
        let sum = trimmed.reduce(0, +)
        return sum / Double(trimmed.count)
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
