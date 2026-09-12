import XCTest
@testable import CubeNotch

/// Semantic checks: every OLL/PLL primary alg has a real recognition state, and
/// cached diagrams match that state (U-face + side-top yellows / PLL face colors).
final class DiagnosticsTests: XCTestCase {

    func testAllLastLayerAlgsAreValid() {
        var failures: [String] = []
        for c in AlgorithmDatabase.ollCases + AlgorithmDatabase.pllCases {
            if CubeEngine.recognitionState(alg: c.primaryAlgorithm) == nil {
                failures.append(c.id)
            }
        }
        XCTAssertTrue(failures.isEmpty, "Invalid last-layer algs: \(failures)")
    }

    func testOLLSemantics() {
        var invalid: [String] = []
        var mismatches: [String] = []
        for c in AlgorithmDatabase.ollCases {
            guard let state = CubeEngine.recognitionState(alg: c.primaryAlgorithm) else {
                invalid.append(c.id)
                continue
            }
            guard let pat = StickerDatabase.pattern(for: c.id) else {
                mismatches.append("\(c.id) missing pattern")
                continue
            }
            let yellow = pat.uFace.map { $0 == .yellow }
            if yellow != state.uFaceYellow {
                mismatches.append("\(c.id) u-face")
            }
            if StickerDatabase.engineSideTopYellow(from: pat) != state.sideTopYellow {
                mismatches.append("\(c.id) side-yellow")
            }
        }
        XCTAssertTrue(invalid.isEmpty, "Invalid OLL algs: \(invalid)")
        XCTAssertTrue(mismatches.isEmpty, "OLL diagram mismatches: \(mismatches.count) \(mismatches)")
    }

    func testPLLSemantics() {
        var failures: [String] = []
        var mismatches: [String] = []
        for c in AlgorithmDatabase.pllCases {
            guard let state = CubeEngine.recognitionState(alg: c.primaryAlgorithm) else {
                failures.append(c.id)
                continue
            }
            XCTAssertTrue(state.firstTwoLayersSolved, "\(c.id) F2L not solved")
            XCTAssertTrue(state.uFaceYellow.allSatisfy { $0 }, "\(c.id) U not all yellow")
            guard let pat = StickerDatabase.pattern(for: c.id) else {
                mismatches.append("\(c.id) missing pattern")
                continue
            }
            let expected = StickerDatabase.displayPattern(from: state, ollOrientationMask: false)
            if pat != expected {
                mismatches.append(c.id)
            }
        }
        XCTAssertTrue(failures.isEmpty, "Invalid PLL algs: \(failures)")
        XCTAssertTrue(mismatches.isEmpty, "PLL diagram mismatches: \(mismatches)")
    }
}
