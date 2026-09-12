import XCTest
@testable import CubeNotch

final class SolveTimerTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "CubeNotch.SolveTimerTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testStoppingDoesNotAutomaticallyBeginAnotherInspection() {
        defaults.set(true, forKey: UDKey.wcaInspection)
        let timer = SolveTimer(defaults: defaults)
        timer.start()
        timer.toggle()
        RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        XCTAssertEqual(timer.state, .stopped)
        XCTAssertFalse(timer.isInspecting)
        timer.reset()
    }

    func testInspectionPenaltySurvivesStartingTheSolve() {
        let timer = SolveTimer(defaults: defaults)
        timer.start()
        timer.stop()
        timer.toggle()
        XCTAssertTrue(timer.isInspecting)
        timer.inspectionRemaining = -0.5
        timer.toggle()
        XCTAssertEqual(timer.state, .running)
        XCTAssertEqual(timer.lastSolvePenalty, .plusTwo)
        timer.reset()
    }

    func testResetCancelsInspection() {
        let timer = SolveTimer(defaults: defaults)
        timer.start()
        timer.stop()
        timer.toggle()
        XCTAssertTrue(timer.isInspecting)
        timer.reset()
        XCTAssertFalse(timer.isInspecting)
        XCTAssertEqual(timer.state, .idle)
    }

    func testStartsInIdle() {
        let timer = SolveTimer(defaults: defaults)
        XCTAssertEqual(timer.state, .idle)
    }

    func testStartSetsRunning() {
        let timer = SolveTimer(defaults: defaults)
        timer.start()
        XCTAssertEqual(timer.state, .running)
    }

    func testStopSetsStoppedAndHasFinalTime() {
        let timer = SolveTimer(defaults: defaults)
        timer.start()
        // Let a tiny bit of time pass (simulated by direct stop)
        timer.stop()
        XCTAssertEqual(timer.state, .stopped)
        XCTAssertNotNil(timer.finalTime)
    }

    func testResetClearsToIdle() {
        let timer = SolveTimer(defaults: defaults)
        timer.start()
        timer.stop()
        timer.reset()
        XCTAssertEqual(timer.state, .idle)
        XCTAssertNil(timer.finalTime)
    }

    func testToggleFromIdleToRunning() {
        let timer = SolveTimer(defaults: defaults)
        XCTAssertEqual(timer.state, .idle)
        timer.toggle() // idle does nothing now (hold-to-arm path)
        XCTAssertEqual(timer.state, .idle)
    }

    func testToggleFromRunningToStopped() {
        let timer = SolveTimer(defaults: defaults)
        timer.start() // use start directly (toggle from idle no longer starts)
        XCTAssertEqual(timer.state, .running)
        timer.toggle() // running -> stopped
        XCTAssertEqual(timer.state, .stopped)
    }

    func testToggleFromStoppedStartsFreshRunning() {
        // With WCA Inspection OFF, stopped → toggle must start running immediately
        defaults.set(false, forKey: UDKey.wcaInspection)
        let timer = SolveTimer(defaults: defaults)
        timer.start()
        timer.toggle() // -> stopped
        timer.toggle() // from stopped should go directly to running (or inspection)
        XCTAssertEqual(timer.state, .running)
        XCTAssertNil(timer.finalTime)
        defaults.removeObject(forKey: UDKey.wcaInspection)
    }

    func testRepeatedPlusTwoTogglesDisplayWithoutChangingRawElapsed() throws {
        let timer = SolveTimer(defaults: defaults)
        timer.start()
        timer.stop()
        let raw = try XCTUnwrap(timer.finalTime)
        let rawDisplay = timer.formattedTime

        timer.applyPenalty(.plusTwo)
        XCTAssertEqual(timer.finalTime ?? -1, raw, accuracy: 0.000_001)
        XCTAssertEqual(timer.lastSolvePenalty, .plusTwo)
        XCTAssertEqual(timer.formattedTime, Self.formatElapsed(raw + 2))
        XCTAssertNotEqual(timer.formattedTime, rawDisplay)

        timer.applyPenalty(.plusTwo)
        XCTAssertEqual(timer.finalTime ?? -1, raw, accuracy: 0.000_001)
        XCTAssertEqual(timer.lastSolvePenalty, .none)
        XCTAssertEqual(timer.formattedTime, rawDisplay)
    }

    func testDNFAndPlusTwoTransitionsKeepRawElapsed() throws {
        let timer = SolveTimer(defaults: defaults)
        timer.start()
        timer.stop()
        let raw = try XCTUnwrap(timer.finalTime)

        timer.applyPenalty(.dnf)
        XCTAssertEqual(timer.finalTime ?? -1, raw, accuracy: 0.000_001)
        XCTAssertEqual(timer.lastSolvePenalty, .dnf)
        XCTAssertEqual(timer.formattedTime, "DNF")

        timer.applyPenalty(.plusTwo)
        XCTAssertEqual(timer.finalTime ?? -1, raw, accuracy: 0.000_001)
        XCTAssertEqual(timer.lastSolvePenalty, .dnf)
        XCTAssertEqual(timer.formattedTime, "DNF")

        timer.applyPenalty(.none)
        XCTAssertEqual(timer.finalTime ?? -1, raw, accuracy: 0.000_001)
        XCTAssertEqual(timer.lastSolvePenalty, .none)
        XCTAssertEqual(timer.formattedTime, Self.formatElapsed(raw))

        timer.applyPenalty(.plusTwo)
        timer.applyPenalty(.dnf)
        XCTAssertEqual(timer.finalTime ?? -1, raw, accuracy: 0.000_001)
        XCTAssertEqual(timer.lastSolvePenalty, .dnf)
        XCTAssertEqual(timer.formattedTime, "DNF")
    }

    func testStoppedPenaltyButtonsKeepTimerDisplayAlignedWithStore() throws {
        let timer = SolveTimer(defaults: defaults)
        let store = TimeStore(defaults: defaults)
        timer.start()
        timer.stop()
        let raw = try XCTUnwrap(timer.finalTime)
        store.addSolve(time: raw, scramble: timer.scramble, penalty: timer.lastSolvePenalty)

        TimerPenaltyControls.apply(.plusTwo, timer: timer, store: store)
        XCTAssertEqual(timer.finalTime ?? -1, raw, accuracy: 0.000_001)
        XCTAssertEqual(store.solves[0].time, raw, accuracy: 0.000_001)
        XCTAssertEqual(timer.lastSolvePenalty, store.solves[0].penalty)
        XCTAssertEqual(timer.lastSolvePenalty, .plusTwo)
        XCTAssertEqual(timer.formattedTime, Self.formatElapsed(raw + 2))

        TimerPenaltyControls.apply(.plusTwo, timer: timer, store: store)
        XCTAssertEqual(timer.finalTime ?? -1, raw, accuracy: 0.000_001)
        XCTAssertEqual(store.solves[0].time, raw, accuracy: 0.000_001)
        XCTAssertEqual(timer.lastSolvePenalty, .none)
        XCTAssertEqual(store.solves[0].penalty, .none)
        XCTAssertEqual(timer.formattedTime, Self.formatElapsed(raw))

        TimerPenaltyControls.apply(.dnf, timer: timer, store: store)
        XCTAssertEqual(timer.finalTime ?? -1, raw, accuracy: 0.000_001)
        XCTAssertEqual(store.solves[0].time, raw, accuracy: 0.000_001)
        XCTAssertEqual(timer.lastSolvePenalty, .dnf)
        XCTAssertEqual(store.solves[0].penalty, .dnf)
        XCTAssertEqual(timer.formattedTime, "DNF")
        XCTAssertNil(store.bestTime)
    }

    private static func formatElapsed(_ t: TimeInterval) -> String {
        let minutes = Int(t) / 60
        let seconds = t.truncatingRemainder(dividingBy: 60)
        if minutes > 0 {
            return String(format: "%d:%05.2f", minutes, seconds)
        }
        return String(format: "%.2f", seconds)
    }
}
