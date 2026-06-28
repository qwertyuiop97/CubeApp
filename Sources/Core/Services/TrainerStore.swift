import Foundation
import SwiftUI

public struct TrainerStats: Codable, Equatable {
    public var attemptCount: Int = 0
    public var correctCount: Int = 0

    public var accuracy: Double {
        guard attemptCount > 0 else { return 0 }
        return Double(correctCount) / Double(attemptCount)
    }

    public var missRate: Double {
        guard attemptCount > 0 else { return 0.5 } // default for unseen
        return 1.0 - accuracy
    }
}

public final class TrainerStore: ObservableObject {
    @Published public private(set) var stats: [String: TrainerStats] = [:] // key = case id like "OLL-1"

    private let storageKey = UDKey.cubeNotchTrainerStats

    public init() {
        load()
    }

    public func recordAttempt(for caseID: String, correct: Bool) {
        var s = stats[caseID] ?? TrainerStats()
        s.attemptCount += 1
        if correct {
            s.correctCount += 1
        }
        stats[caseID] = s
        save()
    }

    public func stats(for caseID: String) -> TrainerStats {
        stats[caseID] ?? TrainerStats()
    }

    public func accuracy(for caseID: String) -> Double {
        stats(for: caseID).accuracy
    }

    // Weighted random: higher miss rate = higher chance
    public func randomCase(from cases: [CubeCase]) -> CubeCase? {
        guard !cases.isEmpty else { return nil }

        let weighted = cases.map { c -> (CubeCase, Double) in
            let rate = stats(for: c.id).missRate
            return (c, rate + 0.1) // small bias so new cases still get picked
        }

        let total = weighted.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return cases.randomElement() }

        var r = Double.random(in: 0..<total)
        for (c, w) in weighted {
            r -= w
            if r <= 0 {
                return c
            }
        }
        return cases.last
    }

    public func reset() {
        stats.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: TrainerStats].self, from: data) else {
            stats = [:]
            return
        }
        stats = decoded
    }
}
