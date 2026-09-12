import XCTest
@testable import CubeNotch

final class TimeStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "TimeStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    private func makeStore() -> TimeStore {
        TimeStore(defaults: defaults)
    }

    func testAo5ReturnsNilWhenFewerThan5() {
        let store = makeStore()
        store.clearSession()
        XCTAssertNil(store.ao5)
        store.addSolve(time: 1.0, scramble: "U")
        XCTAssertNil(store.ao5)
    }

    func testAo5UsesTrimmedMean() {
        let store = makeStore()
        store.clearSession()
        // Add older solves first (they end up at the back)
        store.addSolve(time: 100, scramble: "U")
        store.addSolve(time: 200, scramble: "U")
        // Most recent 5 (will be prefix after insert-at-0): 20,30,40,50,60
        let recent: [TimeInterval] = [20, 30, 40, 50, 60]
        for t in recent { store.addSolve(time: t, scramble: "U") }
        // trimmed: drop 20 and 60 -> 30,40,50 average = 40
        let ao5 = store.ao5 ?? -1
        XCTAssertEqual(ao5, 40.0, accuracy: 0.001)
    }

    func testAo12AndAo100SameLogic() {
        let store = makeStore()
        store.clearSession()
        // Older first
        for i in 100..<110 { store.addSolve(time: Double(i), scramble: "U") }
        // Most recent 12: 1 through 12
        for i in 1...12 { store.addSolve(time: Double(i), scramble: "U") }
        // trimmed 1..12 -> drop 1+12, middle 2..11 avg = 6.5
        let ao12 = store.ao12 ?? -1
        XCTAssertEqual(ao12, 6.5, accuracy: 0.001)
    }

    func testBestTimeReturnsMinimumIgnoringDNF() {
        let store = makeStore()
        store.clearSession()
        store.addSolve(time: 5.0, scramble: "U")
        store.addSolve(time: 3.0, scramble: "U")
        store.addSolve(time: -1, scramble: "U", penalty: .dnf)
        let best = store.bestTime ?? -1
        XCTAssertEqual(best, 3.0, accuracy: 0.001)
    }

    func testClearSessionEmptiesAll() {
        let store = makeStore()
        store.addSolve(time: 1.0, scramble: "U")
        store.clearSession()
        XCTAssertTrue(store.solves.isEmpty)
    }

    func testUpdateLastSolveTogglesPlusTwoNoneAndDNFWithoutMutatingRawTime() {
        let store = makeStore()
        store.addSolve(time: 10.0, scramble: "U")

        store.updateLastSolve(addPenalty: .plusTwo)
        XCTAssertEqual(store.solves[0].time, 10.0, accuracy: 0.001)
        XCTAssertEqual(store.solves[0].penalty, .plusTwo)
        XCTAssertEqual(store.bestTime ?? -1, 12.0, accuracy: 0.001)

        store.updateLastSolve(addPenalty: .plusTwo)
        XCTAssertEqual(store.solves[0].time, 10.0, accuracy: 0.001)
        XCTAssertEqual(store.solves[0].penalty, .none)
        XCTAssertEqual(store.bestTime ?? -1, 10.0, accuracy: 0.001)

        store.updateLastSolve(addPenalty: .dnf)
        XCTAssertEqual(store.solves[0].time, 10.0, accuracy: 0.001)
        XCTAssertEqual(store.solves[0].penalty, .dnf)
        XCTAssertNil(store.bestTime)

        store.updateLastSolve(addPenalty: .none)
        XCTAssertEqual(store.solves[0].time, 10.0, accuracy: 0.001)
        XCTAssertEqual(store.solves[0].penalty, .none)
        XCTAssertEqual(store.bestTime ?? -1, 10.0, accuracy: 0.001)

        store.updateLastSolve(addPenalty: .plusTwo)
        store.updateLastSolve(addPenalty: .dnf)
        XCTAssertEqual(store.solves[0].time, 10.0, accuracy: 0.001)
        XCTAssertEqual(store.solves[0].penalty, .dnf)
    }

    func testPenaltyPersistsRawElapsedAndPenaltyFlag() {
        let store = makeStore()
        store.addSolve(time: 10.0, scramble: "U")
        store.updateLastSolve(addPenalty: .plusTwo)

        let reloaded = makeStore()
        XCTAssertEqual(reloaded.solves.count, 1)
        XCTAssertEqual(reloaded.solves[0].time, 10.0, accuracy: 0.001)
        XCTAssertEqual(reloaded.solves[0].penalty, .plusTwo)
        XCTAssertEqual(reloaded.meanOfSession ?? -1, 12.0, accuracy: 0.001)
        XCTAssertEqual(reloaded.bestTime ?? -1, 12.0, accuracy: 0.001)
    }

    func testMeanOfSessionUsesEffectiveTimeAndExcludesDNF() {
        let store = makeStore()
        store.addSolve(time: 10.0, scramble: "U")
        store.addSolve(time: 10.0, scramble: "U")
        store.updateLastSolve(addPenalty: .plusTwo)
        XCTAssertEqual(store.meanOfSession ?? -1, 11.0, accuracy: 0.001)

        store.addSolve(time: 8.0, scramble: "U")
        store.updateLastSolve(addPenalty: .dnf)
        XCTAssertEqual(store.meanOfSession ?? -1, 11.0, accuracy: 0.001)
    }

    func testNewPBNotifiesOnlyWhenNewEligibleSolveBeatsPriorPB() {
        defaults.set(
            ["single": 5.0, "ao5": -1.0, "ao12": -1.0, "ao100": -1.0],
            forKey: UDKey.cubeNotchPersonalBests
        )
        let store = makeStore()
        XCTAssertEqual(store.pbSingle ?? -1, 5.0, accuracy: 0.001)

        store.addSolve(time: 6.0, scramble: "U")
        XCTAssertNil(store.newPBMessage)
        XCTAssertEqual(store.pbSingle ?? -1, 5.0, accuracy: 0.001)

        store.addSolve(time: 5.0, scramble: "U")
        XCTAssertNil(store.newPBMessage)
        XCTAssertEqual(store.pbSingle ?? -1, 5.0, accuracy: 0.001)

        store.addSolve(time: 4.0, scramble: "U", penalty: .dnf)
        XCTAssertNil(store.newPBMessage)
        XCTAssertEqual(store.pbSingle ?? -1, 5.0, accuracy: 0.001)

        store.addSolve(time: 4.0, scramble: "U")
        XCTAssertEqual(store.newPBMessage, "🎉 New PB!")
        XCTAssertEqual(store.pbSingle ?? -1, 4.0, accuracy: 0.001)
    }

    func testPosthocPenaltyRecomputesSessionPBSingle() {
        let store = makeStore()
        store.addSolve(time: 12.0, scramble: "U")
        store.addSolve(time: 10.0, scramble: "U")
        XCTAssertEqual(store.pbSingle ?? -1, 10.0, accuracy: 0.001)

        store.updateLastSolve(addPenalty: .plusTwo)
        XCTAssertEqual(store.solves[0].time, 10.0, accuracy: 0.001)
        XCTAssertEqual(store.pbSingle ?? -1, 12.0, accuracy: 0.001)

        store.updateLastSolve(addPenalty: .plusTwo)
        XCTAssertEqual(store.solves[0].penalty, .none)
        XCTAssertEqual(store.pbSingle ?? -1, 10.0, accuracy: 0.001)

        store.updateLastSolve(addPenalty: .dnf)
        XCTAssertEqual(store.pbSingle ?? -1, 12.0, accuracy: 0.001)
    }

    func testClearedSessionHistoricalPBSurvivesWorseCurrentSessionPenalty() {
        let store = makeStore()
        store.addSolve(time: 8.0, scramble: "U")
        XCTAssertEqual(store.pbSingle ?? -1, 8.0, accuracy: 0.001)
        store.clearSession()
        XCTAssertEqual(store.pbSingle ?? -1, 8.0, accuracy: 0.001)

        store.addSolve(time: 9.0, scramble: "U")
        XCTAssertEqual(store.pbSingle ?? -1, 8.0, accuracy: 0.001)
        store.updateLastSolve(addPenalty: .plusTwo)
        XCTAssertEqual(store.pbSingle ?? -1, 8.0, accuracy: 0.001)

        let reloaded = makeStore()
        XCTAssertEqual(reloaded.pbSingle ?? -1, 8.0, accuracy: 0.001)
        XCTAssertEqual(reloaded.solves[0].time, 9.0, accuracy: 0.001)
        XCTAssertEqual(reloaded.solves[0].penalty, .plusTwo)
    }

    func testNewSessionPBFallsBackToHistoricalFloorAfterPenalty() {
        let store = makeStore()
        store.addSolve(time: 8.0, scramble: "U")
        store.clearSession()

        store.addSolve(time: 7.0, scramble: "U")
        XCTAssertEqual(store.pbSingle ?? -1, 7.0, accuracy: 0.001)
        store.updateLastSolve(addPenalty: .plusTwo)
        XCTAssertEqual(store.pbSingle ?? -1, 8.0, accuracy: 0.001)

        let reloaded = makeStore()
        XCTAssertEqual(reloaded.pbSingle ?? -1, 8.0, accuracy: 0.001)
        reloaded.updateLastSolve(addPenalty: .plusTwo)
        XCTAssertEqual(reloaded.solves[0].penalty, .none)
        XCTAssertEqual(reloaded.pbSingle ?? -1, 7.0, accuracy: 0.001)
    }

    func testLegacySavedPBIsPreservedWhenCurrentSessionCannotJustifyIt() {
        defaults.set(
            ["single": 5.0, "ao5": 6.0, "ao12": -1.0, "ao100": -1.0],
            forKey: UDKey.cubeNotchPersonalBests
        )
        let store = makeStore()
        store.addSolve(time: 9.0, scramble: "U")
        XCTAssertEqual(store.pbSingle ?? -1, 5.0, accuracy: 0.001)
        XCTAssertEqual(store.pbAo5 ?? -1, 6.0, accuracy: 0.001)

        store.updateLastSolve(addPenalty: .plusTwo)
        XCTAssertEqual(store.pbSingle ?? -1, 5.0, accuracy: 0.001)
        XCTAssertEqual(store.pbAo5 ?? -1, 6.0, accuracy: 0.001)

        let reloaded = makeStore()
        XCTAssertEqual(reloaded.pbSingle ?? -1, 5.0, accuracy: 0.001)
        XCTAssertEqual(reloaded.pbAo5 ?? -1, 6.0, accuracy: 0.001)
    }

    func testPosthocPenaltyRecomputesCurrentAo5WhenItWasThePB() {
        let store = makeStore()
        for t in [20.0, 19.0, 18.0, 17.0, 16.0] {
            store.addSolve(time: t, scramble: "U")
        }
        // current ao5 trimmed: drop 16 and 20 -> 17,18,19 avg = 18
        XCTAssertEqual(store.ao5 ?? -1, 18.0, accuracy: 0.001)
        XCTAssertEqual(store.pbAo5 ?? -1, 18.0, accuracy: 0.001)

        store.updateLastSolve(addPenalty: .plusTwo) // 16 -> 18
        // window 18,17,18,19,20 drop 17 and 20 -> 18,18,19 avg = 18.333...
        XCTAssertEqual(store.ao5 ?? -1, 55.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(store.pbAo5 ?? -1, 55.0 / 3.0, accuracy: 0.001)
    }

    func testNamedSessionAo5PBFallsBackToOtherSessionWindowNotStaleFloor() {
        let store = makeStore()
        for t in [30.0, 15.0, 14.0, 13.0, 12.0] {
            store.addSolve(time: t, scramble: "U")
        }
        // Default ao5: 12,13,14,15,30 drop 12+30 -> 14
        XCTAssertEqual(store.ao5 ?? -1, 14.0, accuracy: 0.001)
        XCTAssertEqual(store.pbAo5 ?? -1, 14.0, accuracy: 0.001)

        store.startNewNamedSession(name: "B")
        for t in [30.0, 11.0, 10.0, 9.0, 8.0] {
            store.addSolve(time: t, scramble: "U")
        }
        // B ao5: 8,9,10,11,30 drop 8+30 -> 10
        XCTAssertEqual(store.ao5 ?? -1, 10.0, accuracy: 0.001)
        XCTAssertEqual(store.pbAo5 ?? -1, 10.0, accuracy: 0.001)

        store.updateLastSolve(addPenalty: .dnf)
        // B current 17; Default window still 14 and reconstructable
        XCTAssertEqual(store.ao5 ?? -1, 17.0, accuracy: 0.001)
        XCTAssertEqual(store.pbAo5 ?? -1, 14.0, accuracy: 0.001)

        store.startNewNamedSession(name: "Default")
        store.updateLastSolve(addPenalty: .dnf)
        // Default current ~19.67; B remaining 17
        XCTAssertEqual(store.pbAo5 ?? -1, 17.0, accuracy: 0.001)

        let reloaded = makeStore()
        XCTAssertEqual(reloaded.pbAo5 ?? -1, 17.0, accuracy: 0.001)
        reloaded.startNewNamedSession(name: "B")
        XCTAssertEqual(reloaded.ao5 ?? -1, 17.0, accuracy: 0.001)
    }

    func testNamedSessionAo12AndAo100PBFallsBackToOtherSessionWindowNotStaleFloor() {
        assertNamedSessionAveragePBFallback(count: 12, read: { $0.ao12 }, pb: { $0.pbAo12 })
        assertNamedSessionAveragePBFallback(count: 100, read: { $0.ao100 }, pb: { $0.pbAo100 })
    }

    private func assertNamedSessionAveragePBFallback(
        count: Int,
        read: (TimeStore) -> TimeInterval?,
        pb: (TimeStore) -> TimeInterval?
    ) {
        let localSuite = "TimeStoreTests.avg.\(count).\(UUID().uuidString)"
        let localDefaults = UserDefaults(suiteName: localSuite)!
        localDefaults.removePersistentDomain(forName: localSuite)
        defer { localDefaults.removePersistentDomain(forName: localSuite) }

        let store = TimeStore(defaults: localDefaults)
        let outlier = 10_000.0
        for i in 0..<(count - 2) {
            store.addSolve(time: 20.0 + Double(i), scramble: "U")
        }
        store.addSolve(time: outlier, scramble: "U")
        store.addSolve(time: 10.0, scramble: "U")
        let defaultAverage = read(store)
        XCTAssertNotNil(defaultAverage, "ao\(count) should exist on Default")
        XCTAssertEqual(pb(store) ?? -1, defaultAverage ?? -1, accuracy: 0.001)

        store.startNewNamedSession(name: "B")
        for i in 0..<(count - 2) {
            store.addSolve(time: 5.0 + Double(i), scramble: "U")
        }
        store.addSolve(time: outlier, scramble: "U")
        store.addSolve(time: 1.0, scramble: "U")
        let bAverage = read(store)
        XCTAssertNotNil(bAverage)
        XCTAssertEqual(pb(store) ?? -1, bAverage ?? -1, accuracy: 0.001)
        XCTAssertLessThan(bAverage ?? .greatestFiniteMagnitude, defaultAverage ?? 0)

        store.updateLastSolve(addPenalty: .dnf)
        let bAfterDNF = read(store)
        XCTAssertNotNil(bAfterDNF)
        XCTAssertGreaterThan(bAfterDNF ?? 0, defaultAverage ?? 0)
        XCTAssertEqual(pb(store) ?? -1, defaultAverage ?? -1, accuracy: 0.001)

        store.startNewNamedSession(name: "Default")
        store.updateLastSolve(addPenalty: .dnf)
        XCTAssertEqual(pb(store) ?? -1, bAfterDNF ?? -1, accuracy: 0.001)

        let reloaded = TimeStore(defaults: localDefaults)
        XCTAssertEqual(pb(reloaded) ?? -1, bAfterDNF ?? -1, accuracy: 0.001)
        reloaded.startNewNamedSession(name: "B")
        XCTAssertEqual(read(reloaded) ?? -1, bAfterDNF ?? -1, accuracy: 0.001)
    }
}
