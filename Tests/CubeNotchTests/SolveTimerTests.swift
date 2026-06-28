import XCTest
@testable import CubeNotch

final class SolveTimerTests: XCTestCase {
    func testStartsInIdle() {
        let timer = SolveTimer()
        XCTAssertEqual(timer.state, .idle)
    }

    func testStartSetsRunning() {
        let timer = SolveTimer()
        timer.start()
        XCTAssertEqual(timer.state, .running)
    }

    func testStopSetsStoppedAndHasFinalTime() {
        let timer = SolveTimer()
        timer.start()
        // Let a tiny bit of time pass (simulated by direct stop)
        timer.stop()
        XCTAssertEqual(timer.state, .stopped)
        XCTAssertNotNil(timer.finalTime)
    }

    func testResetClearsToIdle() {
        let timer = SolveTimer()
        timer.start()
        timer.stop()
        timer.reset()
        XCTAssertEqual(timer.state, .idle)
        XCTAssertNil(timer.finalTime)
    }

    func testToggleFromIdleToRunning() {
        let timer = SolveTimer()
        XCTAssertEqual(timer.state, .idle)
        timer.toggle()
        XCTAssertEqual(timer.state, .running)
    }

    func testToggleFromRunningToStopped() {
        let timer = SolveTimer()
        timer.toggle() // idle -> running
        XCTAssertEqual(timer.state, .running)
        timer.toggle() // running -> stopped
        XCTAssertEqual(timer.state, .stopped)
    }

    func testToggleFromStoppedStartsFreshRunning() {
        // With WCA Inspection OFF, stopped → toggle must start running immediately
        UserDefaults.standard.set(false, forKey: "wcaInspection")
        let timer = SolveTimer()
        timer.toggle() // -> running
        timer.toggle() // -> stopped
        timer.toggle() // from stopped should go directly to running
        XCTAssertEqual(timer.state, .running)
        XCTAssertNil(timer.finalTime)
        UserDefaults.standard.removeObject(forKey: "wcaInspection")
    }
}
