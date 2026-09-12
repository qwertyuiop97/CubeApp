import XCTest
@testable import CubeNotch

final class CaseListSectionsTests: XCTestCase {
    func testHistoryHasPinsThenFiveUniqueRecentsAndNeverLosesOlderCases() {
        let cases = Array(AlgorithmDatabase.ollCases.prefix(9))
        let sections = CaseListSections(cases: cases, recentIDs: [cases[1].id, cases[1].id, "unknown"] + cases.map(\.id), pinnedIDs: [cases[0].id], showHistory: true)
        XCTAssertEqual(sections.pinned.map(\.id), [cases[0].id])
        XCTAssertEqual(sections.recent.map(\.id), Array(cases[1...5]).map(\.id))
        XCTAssertEqual(sections.remaining.map(\.id), Array(cases[6...8]).map(\.id))
        let all = sections.pinned + sections.recent + sections.remaining
        XCTAssertEqual(all.count, cases.count)
        XCTAssertEqual(Set(all.map(\.id)), Set(cases.map(\.id)))
    }
    func testRememberDeduplicatesAndKeepsOnlyFiveMostRecentIDs() {
        XCTAssertEqual(CaseListSections.remember("OLL-2", in: ["OLL-1", "OLL-2", "OLL-1", "OLL-3", "OLL-4", "OLL-5", "OLL-6"]), ["OLL-2", "OLL-1", "OLL-3", "OLL-4", "OLL-5"])
    }

    func testSearchIncludesPinnedAndRecentMatchesExactlyOnce() {
        let cases = Array(AlgorithmDatabase.ollCases.prefix(8))
        let sections = CaseListSections(cases: cases, recentIDs: cases.map(\.id), pinnedIDs: [cases[0].id], showHistory: false)
        XCTAssertTrue(sections.pinned.isEmpty)
        XCTAssertTrue(sections.recent.isEmpty)
        XCTAssertEqual(sections.remaining.map(\.id), cases.map(\.id))
    }
}
