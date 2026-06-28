import XCTest
@testable import CubeNotch

final class F2LDatabaseTests: XCTestCase {
    func testHasCorrectF2LCount() {
        XCTAssertEqual(F2LDatabase.f2lCases.count, 41, "Must have exactly 41 F2L cases")
    }

    func testAllCasesAreF2LType() {
        for c in F2LDatabase.f2lCases {
            XCTAssertEqual(c.caseType, "F2L", "Case \(c.id) must have caseType F2L")
        }
    }

    func testEveryCaseHasPrimaryAndAtLeastTwoAlternatives() {
        for c in F2LDatabase.f2lCases {
            XCTAssertFalse(c.primaryAlgorithm.trimmingCharacters(in: .whitespaces).isEmpty, "Case \(c.id) missing primary")
            XCTAssertGreaterThanOrEqual(c.alternativeAlgorithms.count, 2, "Case \(c.id) must have ≥2 alternatives")
            for alt in c.alternativeAlgorithms {
                XCTAssertFalse(alt.trimmingCharacters(in: .whitespaces).isEmpty, "Case \(c.id) has empty alternative")
            }
        }
    }

    func testCaseNumbersAre1To41NoDuplicates() {
        let numbers = F2LDatabase.f2lCases.map { $0.caseNumber }
        let unique = Set(numbers)
        XCTAssertEqual(numbers.count, unique.count, "Duplicate F2L case numbers")
        XCTAssertEqual(numbers.min(), 1)
        XCTAssertEqual(numbers.max(), 41)
    }
}
