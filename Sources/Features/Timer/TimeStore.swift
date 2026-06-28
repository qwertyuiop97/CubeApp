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

    @Published public private(set) var currentSessionName: String = "Default"
    @Published public private(set) var knownSessions: [String] = []

    private let sessionsListKey = UDKey.cubeNotchSessions
    private let currentSessionKey = UDKey.cubeNotchCurrentSession
    private func storageKey(for name: String) -> String { "cubeNotchSession_\(name)" }

    public init() {
        loadSessionsList()
        if let saved = UserDefaults.standard.string(forKey: currentSessionKey) {
            currentSessionName = saved
        }
        load()
        loadPBs()
        lifetimeSolveCount = UserDefaults.standard.integer(forKey: UDKey.cubeNotchLifetimeSolves)
        if let dates = UserDefaults.standard.array(forKey: UDKey.cubeNotchSolveDates) as? [String] {
            solveDateKeys = Set(dates)
        }
    }

    public func addSolve(time: TimeInterval, scramble: String, penalty: Penalty = .none) {
        let record = SolveRecord(time: time, scramble: scramble, penalty: penalty)
        solves.insert(record, at: 0)
        save()
        updatePersonalBests()
        incrementLifetime()
        recordSolveDate(record.date)
        checkAndSetNewPB()
    }

    public func clearSession() {
        solves.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey(for: currentSessionName))
        save()
    }

    public func startNewNamedSession(name: String) {
        if !solves.isEmpty {
            if let data = try? JSONEncoder().encode(solves) {
                UserDefaults.standard.set(data, forKey: storageKey(for: currentSessionName))
            }
        }
        let newName = name.isEmpty ? defaultSessionName() : name
        if !knownSessions.contains(newName) {
            knownSessions.append(newName)
            UserDefaults.standard.set(knownSessions, forKey: sessionsListKey)
        }
        currentSessionName = newName
        UserDefaults.standard.set(newName, forKey: currentSessionKey)
        if let data = UserDefaults.standard.data(forKey: storageKey(for: newName)),
           let decoded = try? JSONDecoder().decode([SolveRecord].self, from: data) {
            solves = decoded
        } else {
            solves = []
        }
        save()
    }

    private func defaultSessionName() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }

    private func loadSessionsList() {
        if let list = UserDefaults.standard.array(forKey: sessionsListKey) as? [String] {
            knownSessions = list
        } else {
            knownSessions = ["Default"]
        }
    }

    // 14A-1 CSV Export (columns: date,time,scramble,penalty,session)
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
        guard let desktop = fm.urls(for: .desktopDirectory, in: .userDomainMask).first else { return nil }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HHmmss"
        let url = desktop.appendingPathComponent("CubeNotch_times_\(df.string(from: Date())).csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    // 14A-3 CSTimer JSON: [[penalty_int, time_ms, comment, timestamp_ms], ...]
    public func exportCSTimerJSON() -> String {
        var items: [[Any]] = []
        for rec in solves {
            let pen: Int = rec.penalty == .plusTwo ? 1 : (rec.penalty == .dnf ? 2 : 0)
            let effective = rec.penalty == .dnf ? 0.0 : rec.time + (rec.penalty == .plusTwo ? 2.0 : 0.0)
            let timeMs = Int(effective * 1000)
            let comment = ""
            let ts = Int(rec.date.timeIntervalSince1970 * 1000)
            items.append([pen, timeMs, comment, ts])
        }
        if let data = try? JSONSerialization.data(withJSONObject: items, options: [.prettyPrinted]),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "[]"
    }

    public func saveCSTimerToDesktop() -> URL? {
        let json = exportCSTimerJSON()
        let fm = FileManager.default
        guard let desktop = fm.urls(for: .desktopDirectory, in: .userDomainMask).first else { return nil }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HHmmss"
        let url = desktop.appendingPathComponent("CubeNotch_cstimer_\(df.string(from: Date())).txt")
        do {
            try json.write(to: url, atomically: true, encoding: .utf8)
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

    @Published public private(set) var lifetimeSolveCount: Int = 0
    @Published public private(set) var newPBMessage: String? = nil

    private let lifetimeKey = UDKey.cubeNotchLifetimeSolves
    private let streakDatesKey = UDKey.cubeNotchSolveDates
    private var solveDateKeys: Set<String> = []

    private func updatePersonalBests() {
        if let b = bestTime { pbSingle = min(pbSingle ?? .greatestFiniteMagnitude, b) }
        if let a5 = ao5 { pbAo5 = min(pbAo5 ?? .greatestFiniteMagnitude, a5) }
        if let a12 = ao12 { pbAo12 = min(pbAo12 ?? .greatestFiniteMagnitude, a12) }
        if let a100 = ao100 { pbAo100 = min(pbAo100 ?? .greatestFiniteMagnitude, a100) }
        savePBs()
    }

    private let pbKey = UDKey.cubeNotchPersonalBests

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
            pbSingle = dict["single"].flatMap { $0 < 0 ? nil : $0 }
            pbAo5    = dict["ao5"].flatMap    { $0 < 0 ? nil : $0 }
            pbAo12   = dict["ao12"].flatMap   { $0 < 0 ? nil : $0 }
            pbAo100  = dict["ao100"].flatMap  { $0 < 0 ? nil : $0 }
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
        guard solves.count >= count else { return nil }
        let window = Array(solves.prefix(count))
        let times = window.map { effectiveTime($0) }.sorted()
        let trimmed = Array(times.dropFirst(trim).dropLast(trim))
        guard !trimmed.isEmpty else { return nil }
        // WCA: if any remaining time is infinity (DNF), the average is DNF
        if trimmed.contains(.greatestFiniteMagnitude) { return nil }
        return trimmed.reduce(0, +) / Double(trimmed.count)
    }

    private func meanOfLast(_ n: Int) -> TimeInterval? {
        let recent = Array(solves.prefix(n))
        guard recent.count >= 1 else { return nil }
        let sum = recent.reduce(0) { $0 + $1.time }
        return sum / Double(recent.count)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(solves) {
            UserDefaults.standard.set(data, forKey: storageKey(for: currentSessionName))
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey(for: currentSessionName)),
              let decoded = try? JSONDecoder().decode([SolveRecord].self, from: data) else {
            solves = []
            return
        }
        solves = decoded
    }

    // 16A-1/16A-2 helpers
    private func incrementLifetime() {
        lifetimeSolveCount += 1
        UserDefaults.standard.set(lifetimeSolveCount, forKey: lifetimeKey)
    }

    private func recordSolveDate(_ date: Date) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let key = df.string(from: date)
        solveDateKeys.insert(key)
        UserDefaults.standard.set(Array(solveDateKeys), forKey: streakDatesKey)
    }

    private func checkAndSetNewPB() {
        // called after addSolve; if any pb changed to a new low, set message briefly
        if let b = bestTime, let cur = pbSingle, b <= cur {
            newPBMessage = "🎉 New PB!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.newPBMessage = nil }
        }
    }

    public var dailyStreak: Int {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let today = df.string(from: Date())
        var streak = 0
        var d = Date()
        while true {
            let k = df.string(from: d)
            if solveDateKeys.contains(k) { streak += 1 } else { break }
            d = Calendar.current.date(byAdding: .day, value: -1, to: d) ?? d
            if streak > 365 { break }
        }
        return streak
    }

    public var meanOfSession: TimeInterval? {
        guard !solves.isEmpty else { return nil }
        let valid = solves.filter { $0.penalty != .dnf }
        guard !valid.isEmpty else { return nil }
        let sum = valid.reduce(0) { $0 + $1.time }
        return sum / Double(valid.count)
    }
}
