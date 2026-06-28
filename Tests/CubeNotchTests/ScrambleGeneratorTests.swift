import XCTest
@testable import CubeNotch

final class ScrambleGeneratorTests: XCTestCase {
    func testGenerate3x3Exactly20Moves() {
        for _ in 0..<100 {
            let s = ScrambleGenerator.generate3x3()
            let moves = s.split(separator: " ").filter { !$0.isEmpty }
            XCTAssertEqual(moves.count, 20, "Must produce exactly 20 moves")
        }
    }

    func testNoConsecutiveSameFace() {
        for _ in 0..<100 {
            let s = ScrambleGenerator.generate3x3()
            let moves = s.split(separator: " ")
            for i in 1..<moves.count {
                let prevFace = String(moves[i-1].prefix(1))
                let currFace = String(moves[i].prefix(1))
                XCTAssertNotEqual(prevFace, currFace, "Consecutive same face in: \(s)")
            }
        }
    }

    func testAllMovesUseValidFaces() {
        let valid = Set(["U", "D", "F", "B", "L", "R"])
        for _ in 0..<100 {
            let s = ScrambleGenerator.generate3x3()
            let moves = s.split(separator: " ")
            for m in moves {
                let face = String(m.prefix(1))
                XCTAssertTrue(valid.contains(face), "Invalid face in: \(s)")
            }
        }
    }
}
