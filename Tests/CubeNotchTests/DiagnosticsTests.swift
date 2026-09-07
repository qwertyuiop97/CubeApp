import XCTest
import SwiftUI
@testable import CubeNotch

/// One-shot diagnostic: verifies every OLL/PLL primary algorithm semantically with the
/// real cube model and dumps the true recognition patterns (used to regenerate
/// StickerDatabase). Findings feed PROBLEMS.md.
final class DiagnosticsTests: XCTestCase {

    private func bits(_ p: [Bool]) -> String { p.map { $0 ? "Y" : "." }.joined() }

    /// Face letters of the 12 side top-row stickers, order F(18,19,20) R(9,10,11) B(45,46,47) L(36,37,38).
    private func sideTopColors(_ c: CubeEngine) -> String {
        let idx = [18, 19, 20, 9, 10, 11, 45, 46, 47, 36, 37, 38]
        let letters = ["U", "R", "F", "D", "L", "B"]
        return idx.map { letters[c.stickers[$0] / 9] }.joined()
    }

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
        print("OLL_PATTERN_DUMP_BEGIN")
        for c in AlgorithmDatabase.ollCases {
            guard let state = CubeEngine.recognitionState(alg: c.primaryAlgorithm) else {
                invalid.append(c.id)
                continue
            }
            let yellow = state.uFaceYellow
            let sides = state.sideTopYellow
            print("OLL \(c.caseNumber): u=[\(bits(yellow))] sides=[\(bits(sides))]")
            if let pat = StickerDatabase.pattern(for: c.id) {
                var match = false
                var r = pat.uFace
                for _ in 0..<4 {
                    if r == yellow { match = true; break }
                    let o = r
                    r = [o[6], o[3], o[0], o[7], o[4], o[1], o[8], o[5], o[2]]
                }
                if !match { mismatches.append("\(c.id): db=[\(bits(pat.uFace))] true=[\(bits(yellow))]") }
            }
        }
        print("OLL_PATTERN_DUMP_END")
        print("OLL_INVALID: \(invalid.isEmpty ? "NONE" : invalid.joined(separator: ","))")
        print("OLL_STICKERDB_MISMATCHES: \(mismatches.count)")
        for m in mismatches { print("  \(m)") }
    }

    func testPLLSemantics() {
        var failures: [String] = []
        print("PLL_PATTERN_DUMP_BEGIN")
        for c in AlgorithmDatabase.pllCases {
            guard let state = CubeEngine.recognitionState(alg: c.primaryAlgorithm) else {
                failures.append(c.id)
                continue
            }
            let f2l = state.firstTwoLayersSolved
            let uAll = state.uFaceYellow.allSatisfy { $0 }
            print("PLL \(c.caseNumber) \(c.name): f2lExact=\(f2l) uAllYellow=\(uAll) sides=\(sideTopColors(state)) storedAuf=\(c.auf ?? "-")")
        }
        print("PLL_PATTERN_DUMP_END")
        XCTAssertTrue(failures.isEmpty, "Invalid PLL algs: \(failures)")
    }
}
