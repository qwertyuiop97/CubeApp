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
    private let defaults: UserDefaults
    private func storageKey(for name: String) -> String { "cubeNotchSession_\(name)" }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadSessionsList()
        if let saved = defaults.string(forKey: currentSessionKey) {
            currentSessionName = saved
        }
        load()
        loadPBs()
        lifetimeSolveCount = defaults.integer(forKey: UDKey.cubeNotchLifetimeSolves)
        if let dates = defaults.array(forKey: UDKey.cubeNotchSolveDates) as? [String] {
            solveDateKeys = Set(dates)
        }
    }

    public func addSolve(time: TimeInterval, scramble: String, penalty: Penalty = .none) {
        let record = SolveRecord(time: time, scramble: scramble, penalty: penalty)
        solves.insert(record, at: 0)
        save()
        let priorPB = pbSingle
        let candidate: TimeInterval? = record.penalty == .dnf ? nil : effectiveTime(record)
        updatePersonalBests()
        incrementLifetime()
        recordSolveDate(record.date)
        checkAndSetNewPB(prior: priorPB, candidate: candidate)
    }

    public func clearSession() {
        solves.removeAll()
        defaults.removeObject(forKey: storageKey(for: currentSessionName))
        absorbDisplayedPBsIntoFloor()
        clearPBSources()
        save()
        savePBs()
        saveProvenance()
    }

    public func startNewNamedSession(name: String) {
        if !solves.isEmpty {
            if let data = try? JSONEncoder().encode(solves) {
                defaults.set(data, forKey: storageKey(for: currentSessionName))
            }
        }
        let newName = name.isEmpty ? defaultSessionName() : name
        if !knownSessions.contains(newName) {
            knownSessions.append(newName)
            defaults.set(knownSessions, forKey: sessionsListKey)
        }
        currentSessionName = newName
        defaults.set(newName, forKey: currentSessionKey)
        if let data = defaults.data(forKey: storageKey(for: newName)),
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
        if let list = defaults.array(forKey: sessionsListKey) as? [String] {
            knownSessions = list
        } else {
            knownSessions = ["Default"]
        }
    }

    // CSV Export (columns: date,time,scramble,penalty,session)
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

    // CSTimer JSON: [[penalty_int, time_ms, comment, timestamp_ms], ...]
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

    // Personal Bests (never cleared by "New Session")
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
        pbSingle = minPresent(pbFloor.single, bestSingleAcrossSessions())
        if let a5 = ao5, a5 < (pbAo5 ?? .greatestFiniteMagnitude) {
            if let previous = pbAo5, !isCurrentPrefix(sourceIDs: ao5SourceIDs) {
                pbFloor.ao5 = minPresent(pbFloor.ao5, previous)
            }
            pbAo5 = a5
            ao5SourceIDs = windowIDs(count: 5)
        }
        if let a12 = ao12, a12 < (pbAo12 ?? .greatestFiniteMagnitude) {
            if let previous = pbAo12, !isCurrentPrefix(sourceIDs: ao12SourceIDs) {
                pbFloor.ao12 = minPresent(pbFloor.ao12, previous)
            }
            pbAo12 = a12
            ao12SourceIDs = windowIDs(count: 12)
        }
        if let a100 = ao100, a100 < (pbAo100 ?? .greatestFiniteMagnitude) {
            if let previous = pbAo100, !isCurrentPrefix(sourceIDs: ao100SourceIDs) {
                pbFloor.ao100 = minPresent(pbFloor.ao100, previous)
            }
            pbAo100 = a100
            ao100SourceIDs = windowIDs(count: 100)
        }
        savePBs()
        saveProvenance()
    }

    private let pbKey = UDKey.cubeNotchPersonalBests
    private let pbProvenanceKey = UDKey.cubeNotchPersonalBests + ".provenance"

    private struct PBFloor {
        var single: TimeInterval?
        var ao5: TimeInterval?
        var ao12: TimeInterval?
        var ao100: TimeInterval?
    }

    private struct StoredPBProvenance: Codable {
        var floorSingle: TimeInterval
        var floorAo5: TimeInterval
        var floorAo12: TimeInterval
        var floorAo100: TimeInterval
        var ao5SolveIDs: [UUID]?
        var ao12SolveIDs: [UUID]?
        var ao100SolveIDs: [UUID]?
    }

    private var pbFloor = PBFloor()
    private var ao5SourceIDs: [UUID]?
    private var ao12SourceIDs: [UUID]?
    private var ao100SourceIDs: [UUID]?

    private func savePBs() {
        let dict: [String: TimeInterval] = [
            "single": pbSingle ?? -1,
            "ao5": pbAo5 ?? -1,
            "ao12": pbAo12 ?? -1,
            "ao100": pbAo100 ?? -1
        ]
        defaults.set(dict, forKey: pbKey)
    }

    private func loadPBs() {
        if let dict = defaults.dictionary(forKey: pbKey) as? [String: TimeInterval] {
            pbSingle = dict["single"].flatMap { $0 < 0 ? nil : $0 }
            pbAo5    = dict["ao5"].flatMap    { $0 < 0 ? nil : $0 }
            pbAo12   = dict["ao12"].flatMap   { $0 < 0 ? nil : $0 }
            pbAo100  = dict["ao100"].flatMap  { $0 < 0 ? nil : $0 }
        }
        loadProvenance()
    }

    private func saveProvenance() {
        let payload = StoredPBProvenance(
            floorSingle: pbFloor.single ?? -1,
            floorAo5: pbFloor.ao5 ?? -1,
            floorAo12: pbFloor.ao12 ?? -1,
            floorAo100: pbFloor.ao100 ?? -1,
            ao5SolveIDs: ao5SourceIDs,
            ao12SolveIDs: ao12SourceIDs,
            ao100SolveIDs: ao100SourceIDs
        )
        if let data = try? JSONEncoder().encode(payload) {
            defaults.set(data, forKey: pbProvenanceKey)
        }
    }

    private func loadProvenance() {
        if let data = defaults.data(forKey: pbProvenanceKey),
           let loaded = try? JSONDecoder().decode(StoredPBProvenance.self, from: data) {
            pbFloor.single = loaded.floorSingle < 0 ? nil : loaded.floorSingle
            pbFloor.ao5 = loaded.floorAo5 < 0 ? nil : loaded.floorAo5
            pbFloor.ao12 = loaded.floorAo12 < 0 ? nil : loaded.floorAo12
            pbFloor.ao100 = loaded.floorAo100 < 0 ? nil : loaded.floorAo100
            ao5SourceIDs = loaded.ao5SolveIDs
            ao12SourceIDs = loaded.ao12SolveIDs
            ao100SourceIDs = loaded.ao100SolveIDs
            return
        }
        seedLegacyFloor()
        saveProvenance()
    }

    /// Legacy aggregates have no source IDs. Keep values that current persisted
    /// sessions cannot reconstruct; attribute current windows that still match.
    private func seedLegacyFloor() {
        let reconstructedSingle = bestSingleAcrossSessions()
        if let saved = pbSingle, reconstructedSingle == nil || saved + 1e-9 < reconstructedSingle! {
            pbFloor.single = saved
        }
        seedLegacyAverageFloor(saved: pbAo5, current: ao5, count: 5) { floor, ids in
            pbFloor.ao5 = floor
            ao5SourceIDs = ids
        }
        seedLegacyAverageFloor(saved: pbAo12, current: ao12, count: 12) { floor, ids in
            pbFloor.ao12 = floor
            ao12SourceIDs = ids
        }
        seedLegacyAverageFloor(saved: pbAo100, current: ao100, count: 100) { floor, ids in
            pbFloor.ao100 = floor
            ao100SourceIDs = ids
        }
    }

    private func seedLegacyAverageFloor(
        saved: TimeInterval?,
        current: TimeInterval?,
        count: Int,
        assign: (TimeInterval?, [UUID]?) -> Void
    ) {
        guard let saved else { return }
        if current == nil || saved + 1e-9 < current! {
            assign(saved, nil)
        } else if let current, abs(saved - current) <= 1e-9 {
            assign(nil, windowIDs(count: count))
        }
    }

    private func absorbDisplayedPBsIntoFloor() {
        pbFloor.single = minPresent(pbFloor.single, pbSingle)
        pbFloor.ao5 = minPresent(pbFloor.ao5, pbAo5)
        pbFloor.ao12 = minPresent(pbFloor.ao12, pbAo12)
        pbFloor.ao100 = minPresent(pbFloor.ao100, pbAo100)
    }

    private func clearPBSources() {
        ao5SourceIDs = nil
        ao12SourceIDs = nil
        ao100SourceIDs = nil
    }

    private func recomputePersonalBestsAfterPenalty() {
        pbSingle = minPresent(pbFloor.single, bestSingleAcrossSessions())
        let ao5Next = recomputeAverageAfterPenalty(
            count: 5,
            displayed: pbAo5,
            floor: pbFloor.ao5,
            sourceIDs: ao5SourceIDs
        )
        pbAo5 = ao5Next.value
        ao5SourceIDs = ao5Next.sourceIDs
        let ao12Next = recomputeAverageAfterPenalty(
            count: 12,
            displayed: pbAo12,
            floor: pbFloor.ao12,
            sourceIDs: ao12SourceIDs
        )
        pbAo12 = ao12Next.value
        ao12SourceIDs = ao12Next.sourceIDs
        let ao100Next = recomputeAverageAfterPenalty(
            count: 100,
            displayed: pbAo100,
            floor: pbFloor.ao100,
            sourceIDs: ao100SourceIDs
        )
        pbAo100 = ao100Next.value
        ao100SourceIDs = ao100Next.sourceIDs
        savePBs()
        saveProvenance()
    }

    private func recomputeAverageAfterPenalty(
        count: Int,
        displayed: TimeInterval?,
        floor: TimeInterval?,
        sourceIDs: [UUID]?
    ) -> (value: TimeInterval?, sourceIDs: [UUID]?) {
        let lastID = solves.first?.id
        let sourceHit = sourceIDs.map { ids in lastID.map { ids.contains($0) } ?? false } ?? false
        let bestCurrent = bestAverageAcrossSessions(count: count)
        if sourceHit {
            let next = minPresent(floor, bestCurrent.value)
            if let next, let bestValue = bestCurrent.value, abs(next - bestValue) <= 1e-9 {
                return (next, bestCurrent.sourceIDs)
            }
            return (next, nil)
        }
        if let bestValue = bestCurrent.value, bestValue < (displayed ?? .greatestFiniteMagnitude) {
            return (bestValue, bestCurrent.sourceIDs)
        }
        return (displayed, sourceIDs)
    }

    private func minPresent(_ a: TimeInterval?, _ b: TimeInterval?) -> TimeInterval? {
        switch (a, b) {
        case (nil, nil): return nil
        case (let x?, nil): return x
        case (nil, let y?): return y
        case (let x?, let y?): return min(x, y)
        }
    }

    private func windowIDs(count: Int) -> [UUID]? {
        guard solves.count >= count else { return nil }
        return Array(solves.prefix(count).map(\.id))
    }

    private func isCurrentPrefix(sourceIDs: [UUID]?) -> Bool {
        guard let sourceIDs, !sourceIDs.isEmpty else { return false }
        for name in sessionNames() {
            let sessionRecords = records(for: name)
            guard sessionRecords.count >= sourceIDs.count else { continue }
            if Array(sessionRecords.prefix(sourceIDs.count).map(\.id)) == sourceIDs {
                return true
            }
        }
        return false
    }

    private func sessionNames() -> Set<String> {
        Set(knownSessions + [currentSessionName])
    }

    private func records(for sessionName: String) -> [SolveRecord] {
        if sessionName == currentSessionName { return solves }
        guard let data = defaults.data(forKey: storageKey(for: sessionName)),
              let decoded = try? JSONDecoder().decode([SolveRecord].self, from: data) else {
            return []
        }
        return decoded
    }

    private func bestSingleAcrossSessions() -> TimeInterval? {
        var best: TimeInterval?
        for name in sessionNames() {
            let sessionBest = records(for: name).filter { $0.penalty != .dnf }.map { effectiveTime($0) }.min()
            best = minPresent(best, sessionBest)
        }
        return best
    }

    private func bestAverageAcrossSessions(count: Int) -> (value: TimeInterval?, sourceIDs: [UUID]?) {
        var best: TimeInterval?
        var bestIDs: [UUID]?
        for name in sessionNames() {
            let sessionRecords = records(for: name)
            guard let avg = trimmedMean(from: sessionRecords, count: count, trim: 1) else { continue }
            if best == nil || avg + 1e-9 < best! {
                best = avg
                bestIDs = sessionRecords.count >= count
                    ? Array(sessionRecords.prefix(count).map(\.id))
                    : nil
            }
        }
        return (best, bestIDs)
    }

    public func updateLastSolve(addPenalty: Penalty) {
        guard var first = solves.first else { return }
        switch addPenalty {
        case .plusTwo:
            if first.penalty == .plusTwo { first.penalty = .none }
            else if first.penalty != .dnf { first.penalty = .plusTwo }
        case .dnf:
            first.penalty = .dnf
        case .none:
            first.penalty = .none
        }
        solves[0] = first
        save()
        recomputePersonalBestsAfterPenalty()
    }

    private func effectiveTime(_ rec: SolveRecord) -> TimeInterval {
        switch rec.penalty {
        case .dnf: return .greatestFiniteMagnitude
        case .plusTwo: return rec.time + 2.0
        case .none: return rec.time
        }
    }

    private func trimmedMean(count: Int, trim: Int) -> TimeInterval? {
        trimmedMean(from: solves, count: count, trim: trim)
    }

    private func trimmedMean(from records: [SolveRecord], count: Int, trim: Int) -> TimeInterval? {
        guard records.count >= count else { return nil }
        let window = Array(records.prefix(count))
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
            defaults.set(data, forKey: storageKey(for: currentSessionName))
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey(for: currentSessionName)),
              let decoded = try? JSONDecoder().decode([SolveRecord].self, from: data) else {
            solves = []
            return
        }
        solves = decoded
    }

    // Lifetime activity
    private func incrementLifetime() {
        lifetimeSolveCount += 1
        defaults.set(lifetimeSolveCount, forKey: lifetimeKey)
    }

    private func recordSolveDate(_ date: Date) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let key = df.string(from: date)
        solveDateKeys.insert(key)
        defaults.set(Array(solveDateKeys), forKey: streakDatesKey)
    }

    private func checkAndSetNewPB(prior: TimeInterval?, candidate: TimeInterval?) {
        guard let candidate else { return }
        let isNewPB = prior.map { candidate < $0 } ?? true
        guard isNewPB else { return }
        newPBMessage = "🎉 New PB!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.newPBMessage = nil }
    }

    public var dailyStreak: Int {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
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
        let sum = valid.reduce(0) { $0 + effectiveTime($1) }
        return sum / Double(valid.count)
    }
}
