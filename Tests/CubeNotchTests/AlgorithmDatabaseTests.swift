import XCTest
@testable import CubeNotch

final class AlgorithmDatabaseTests: XCTestCase {
    func testHasCorrectOLLCount() {
        XCTAssertEqual(AlgorithmDatabase.ollCases.count, 57, "Must have exactly 57 OLL cases")
    }

    func testHasCorrectPLLCount() {
        XCTAssertEqual(AlgorithmDatabase.pllCases.count, 21, "Must have exactly 21 PLL cases")
    }

    func testEveryCaseHasPrimaryAndAtLeastTwoAlternatives() {
        let all = AlgorithmDatabase.ollCases + AlgorithmDatabase.pllCases
        for c in all {
            XCTAssertFalse(c.primaryAlgorithm.trimmingCharacters(in: .whitespaces).isEmpty, "Case \(c.id) missing primary")
            XCTAssertGreaterThanOrEqual(c.alternativeAlgorithms.count, 2, "Case \(c.id) must have ≥2 alternatives")
            for alt in c.alternativeAlgorithms {
                XCTAssertFalse(alt.trimmingCharacters(in: .whitespaces).isEmpty, "Case \(c.id) has empty alternative")
            }
        }
    }

    func testNoDuplicateIDs() {
        let all = AlgorithmDatabase.ollCases + AlgorithmDatabase.pllCases
        let ids = all.map { $0.id }
        let unique = Set(ids)
        XCTAssertEqual(ids.count, unique.count, "Duplicate case IDs found")
    }
}
