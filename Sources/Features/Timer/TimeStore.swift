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
        loadPBs()
    }

    public func addSolve(time: TimeInterval, scramble: String, penalty: Penalty = .none) {
        let record = SolveRecord(time: time, scramble: scramble, penalty: penalty)
        solves.insert(record, at: 0)
        save()
        updatePersonalBests()
    }

    public func clearSession() {
        solves.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
        // PBs are intentionally never cleared
    }

    // 14A-2 Named sessions (basic)
    public var currentSessionName: String = "Default"

    public func setSessionName(_ name: String) {
        currentSessionName = name.isEmpty ? "Default" : name
    }

    // 14A-1 CSV Export
    public func exportCSV() -> String {
        var lines = ["date,time,scramble,penalty,session"]
        let df = ISO8601DateFormatter()
        for rec in solves {
            let dateStr = df.string(from: rec.date)
            let timeStr = String(format: "%.2f", rec.time)
            let pen = rec.penalty.rawValue
            let esc = rec.scramble.replacingOccurrences(of: ",", with: ";")
            lines.append("\(dateStr),\(timeStr),\(esc),\(pen),\(currentSessionName)")
        }
        return lines.joined(separator: "\n")
    }

    public func saveCSVToDesktop() -> URL? {
        let csv = exportCSV()
        let fm = FileManager.default
        let desktop = fm.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let ts = Int(Date().timeIntervalSince1970)
        let url = desktop.appendingPathComponent("CubeNotch_times_\(ts).csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    // ao5/ao12/ao100 use WCA trimmed mean (discard best + worst when >=5/12/100)
    public var ao5: TimeInterval? { trimmedMean(count: 5, trim: 1) }
    public var ao12: TimeInterval? { trimmedMean(count: 12, trim: 1) }
    public var ao100: TimeInterval? { trimmedMean(count: 100, trim: 1) }

    public var bestTime: TimeInterval? {
        solves.filter { $0.penalty != .dnf }.map { effectiveTime($0) }.min()
    }

    // Phase 16A-1: Personal Bests (never cleared by "New Session")
    @Published public private(set) var pbSingle: TimeInterval?
    @Published public private(set) var pbAo5: TimeInterval?
    @Published public private(set) var pbAo12: TimeInterval?
    @Published public private(set) var pbAo100: TimeInterval?

    public func updatePersonalBests() {
        if let b = bestTime { pbSingle = min(pbSingle ?? .greatestFiniteMagnitude, b) }
        if let a5 = ao5 { pbAo5 = min(pbAo5 ?? .greatestFiniteMagnitude, a5) }
        if let a12 = ao12 { pbAo12 = min(pbAo12 ?? .greatestFiniteMagnitude, a12) }
        if let a100 = ao100 { pbAo100 = min(pbAo100 ?? .greatestFiniteMagnitude, a100) }
        savePBs()
    }

    private let pbKey = "cubeNotchPersonalBests"

    private func savePBs() {
        let dict: [String: TimeInterval] = [
            "single": pbSingle ?? -1,
            "ao5": pbAo5 ?? -1,
            "ao12": pbAo12 ?? -1,
            "ao100": pbAo100 ?? -1
        ]
        UserDefaults.standard.set(dict, forKey: pbKey)
    }

    private func loadPBs() {
        if let dict = UserDefaults.standard.dictionary(forKey: pbKey) as? [String: TimeInterval] {
            pbSingle = dict["single"] ?? -1; if pbSingle! < 0 { pbSingle = nil }
            pbAo5 = dict["ao5"] ?? -1; if pbAo5! < 0 { pbAo5 = nil }
            pbAo12 = dict["ao12"] ?? -1; if pbAo12! < 0 { pbAo12 = nil }
            pbAo100 = dict["ao100"] ?? -1; if pbAo100! < 0 { pbAo100 = nil }
        }
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
