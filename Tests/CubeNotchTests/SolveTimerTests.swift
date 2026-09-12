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
}
