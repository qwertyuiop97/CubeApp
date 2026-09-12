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
}
