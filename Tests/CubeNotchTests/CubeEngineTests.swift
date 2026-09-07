import XCTest
@testable import CubeNotch

/// Algebraic verification of the move engine. If any cycle table were wrong,
/// these group-theoretic identities would fail.
final class CubeEngineTests: XCTestCase {

    private func order(of alg: String, max: Int = 24) -> Int {
        let target = CubeEngine()
        var cube = CubeEngine.applying(alg)
        var n = 1
        while cube != target && n < max {
            cube.apply(alg)
            n += 1
        }
        return cube == target ? n : -1
    }

    func testQuarterTurnsHaveOrderFour() {
        for move in ["U", "D", "R", "L", "F", "B", "M", "E", "S", "x", "y", "z", "u", "d", "r", "l", "f", "b"] {
            XCTAssertEqual(order(of: move), 4, "\(move) must have order 4")
        }
    }

    func testSexyMoveOrderSix() {
        XCTAssertEqual(order(of: "R U R' U'"), 6)
    }

    func testSuneOrderSix() {
        XCTAssertEqual(order(of: "R U R' U R U2 R'"), 6)
    }

    func testPermutationAlgsHaveExpectedOrders() {
        XCTAssertEqual(order(of: "R U R' U' R' F R2 U' R' U' R U R' F'"), 2, "T perm")
        XCTAssertEqual(order(of: "M2 U M2 U2 M2 U M2"), 2, "H perm")
        XCTAssertEqual(order(of: "M2 U M2 U M' U2 M2 U2 M'"), 2, "Z perm")
        XCTAssertEqual(order(of: "R U' R U R U R U' R' U' R2"), 3, "Ua perm (3-cycle)")
        XCTAssertEqual(order(of: "x R' U R' D2 R U' R' D2 R2 x'"), 3, "Aa perm (3-cycle)")
    }

    func testPieceIdentityUnderU() {
        // Faces: U=0 R=1 F=2 D=3 L=4 B=5. U turns the U layer so each piece
        // moves UFR->UFL, UFL->ULB, ULB->UBR, UBR->UFR (front to left).
        var cube = CubeEngine()
        cube.apply("U")
        XCTAssertEqual(cube.cornerOccupancy()["UFL"], [0, 1, 2], "UFR piece lands on UFL")
        XCTAssertEqual(cube.cornerOccupancy()["ULB"], [0, 2, 4], "UFL piece lands on ULB")
        XCTAssertEqual(cube.cornerOccupancy()["UBR"], [0, 4, 5], "ULB piece lands on UBR")
        XCTAssertEqual(cube.cornerOccupancy()["UFR"], [0, 1, 5], "UBR piece lands on UFR")
        XCTAssertEqual(cube.cornerOccupancy()["DFR"], [1, 2, 3], "D layer untouched")
        // Edges: UF->UL, UL->UB, UB->UR, UR->UF
        XCTAssertEqual(cube.edgeOccupancy()["UL"], [0, 2], "UF piece lands on UL")
        XCTAssertEqual(cube.edgeOccupancy()["UR"], [0, 5], "UB piece lands on UR")
    }

    func testPieceIdentityUnderR() {
        // R brings FR up to UR, UR back to BR, BR down to DR, DR front to FR.
        var cube = CubeEngine()
        cube.apply("R")
        XCTAssertEqual(cube.edgeOccupancy()["UR"], [1, 2], "FR piece (F,R) lands on UR")
        XCTAssertEqual(cube.edgeOccupancy()["BR"], [0, 1], "UR piece (U,R) lands on BR")
        XCTAssertEqual(cube.edgeOccupancy()["FR"], [1, 3], "DR piece (D,R) lands on FR")
        XCTAssertEqual(cube.cornerOccupancy()["UBR"], [0, 1, 2], "UFR piece lands on UBR")
    }

    func testRotationIdentities() {
        let solved = CubeEngine()
        // Whole-cube rotations equal layer compositions
        XCTAssertEqual(CubeEngine.applying("x").colorScheme, CubeEngine.applying("R M' L'").colorScheme)
        XCTAssertEqual(CubeEngine.applying("y").colorScheme, CubeEngine.applying("U E' D'").colorScheme)
        XCTAssertEqual(CubeEngine.applying("z").colorScheme, CubeEngine.applying("F S B'").colorScheme)
        // Wide moves equal face + slice compositions
        XCTAssertEqual(CubeEngine.applying("r").colorScheme, CubeEngine.applying("R M'").colorScheme)
        XCTAssertEqual(CubeEngine.applying("l").colorScheme, CubeEngine.applying("L M").colorScheme)
        XCTAssertEqual(CubeEngine.applying("u").colorScheme, CubeEngine.applying("U E'").colorScheme)
        XCTAssertEqual(CubeEngine.applying("d").colorScheme, CubeEngine.applying("D E").colorScheme)
        XCTAssertEqual(CubeEngine.applying("f").colorScheme, CubeEngine.applying("F S").colorScheme)
        XCTAssertEqual(CubeEngine.applying("b").colorScheme, CubeEngine.applying("B S'").colorScheme)
        _ = solved
    }

    func testPrimeAndDoubleSuffixes() {
        // R2 == R2' ; R' == R R R ; U2' U == U'
        XCTAssertEqual(CubeEngine.applying("R2").colorScheme, CubeEngine.applying("R2'").colorScheme)
        XCTAssertEqual(CubeEngine.applying("R'").colorScheme, CubeEngine.applying("R R R").colorScheme)
        XCTAssertEqual(CubeEngine.applying("U2' U").colorScheme, CubeEngine.applying("U'").colorScheme)
    }

    func testParserAcceptsValidAndRejectsInvalid() {
        XCTAssertNoThrow(try CubeEngine.parse("R U R' U' R' F R2 U' R' U' R U R' F'"))
        XCTAssertNoThrow(try CubeEngine.parse("x R' U R' D2 R U' R' D2 R2 x'"))
        XCTAssertNoThrow(try CubeEngine.parse("r U R' U' r' F R F' M2' U2 M u f' b2"))
        XCTAssertThrowsError(try CubeEngine.parse("Q U R'"))
        XCTAssertThrowsError(try CubeEngine.parse("R U R#"))
        XCTAssertThrowsError(try CubeEngine.parse("R U 2R"))
        XCTAssertThrowsError(try CubeEngine.parse("   "))
    }

    func testTokenizerHandlesWideAndSlices() {
        let tokens = CubeEngine.tokenize("r U R2' M2'")
        XCTAssertEqual(tokens.count, 4)
        XCTAssertEqual(tokens[0].base, "r")
        XCTAssertEqual(tokens[2].base, "R", "R2' normalizes to base R with 2 turns")
        XCTAssertEqual(tokens[2].turns, 2)
        XCTAssertEqual(tokens[3].base, "M")
        XCTAssertEqual(tokens[3].turns, 2)
    }

    func testSolvedStateDetection() {
        XCTAssertTrue(CubeEngine().isSolved)
        XCTAssertFalse(CubeEngine.applying("R").isSolved)
        XCTAssertTrue(CubeEngine.applying("R R'").isSolved)
    }

    func testPLLOnSolvedKeepsF2L() {
        // A PLL applied to a solved cube must only disturb the U layer.
        for alg in ["R U R' U' R' F R2 U' R' U' R U R' F'",
                    "M2 U M2 U2 M2 U M2",
                    "x R' U R' D2 R U' R' D2 R2 x'"] {
            XCTAssertTrue(CubeEngine.applying(alg).firstTwoLayersSolved, alg)
        }
    }
}
