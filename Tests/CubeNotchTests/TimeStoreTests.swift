import XCTest
@testable import CubeNotch

final class TimeStoreTests: XCTestCase {
    func testAo5ReturnsNilWhenFewerThan5() {
        let store = TimeStore()
        store.clearSession()
        XCTAssertNil(store.ao5)
        store.addSolve(time: 1.0, scramble: "U")
        XCTAssertNil(store.ao5)
    }

    func testAo5UsesTrimmedMean() {
        let store = TimeStore()
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
        let store = TimeStore()
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
        let store = TimeStore()
        store.clearSession()
        store.addSolve(time: 5.0, scramble: "U")
        store.addSolve(time: 3.0, scramble: "U")
        store.addSolve(time: -1, scramble: "U", penalty: .dnf)
        let best = store.bestTime ?? -1
        XCTAssertEqual(best, 3.0, accuracy: 0.001)
    }

    func testClearSessionEmptiesAll() {
        let store = TimeStore()
        store.addSolve(time: 1.0, scramble: "U")
        store.clearSession()
        XCTAssertTrue(store.solves.isEmpty)
    }
}
