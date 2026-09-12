import XCTest
@testable import CubeNotch

final class LastLayerDiagramTests: XCTestCase {

    private func dummyCase(type: String, number: Int, alg: String) -> CubeCase {
        CubeCase(
            caseNumber: number,
            caseType: type,
            name: "test",
            primaryAlgorithm: alg,
            alternativeAlgorithms: ["R U", "U R"],
            diagramImagePlaceholder: "x"
        )
    }

    func testOLLStickerPatternsMatchEngineRecognitionUFace() {
        var mismatches: [String] = []
        for c in AlgorithmDatabase.ollCases {
            guard let state = CubeEngine.recognitionState(alg: c.primaryAlgorithm) else {
                mismatches.append("\(c.id) missing recognition state")
                continue
            }
            guard let pat = StickerDatabase.pattern(for: c.id) else {
                mismatches.append("\(c.id) missing pattern")
                continue
            }
            if pat.uFace.map({ $0 == .yellow }) != state.uFaceYellow {
                mismatches.append(c.id)
            }
        }
        XCTAssertTrue(mismatches.isEmpty, "OLL U-face mismatches: \(mismatches.count) \(mismatches)")
    }

    func testOLLPatternsPreserveYellowSideClues() {
        var mismatches: [String] = []
        var anySideYellow = false
        for c in AlgorithmDatabase.ollCases {
            guard let state = CubeEngine.recognitionState(alg: c.primaryAlgorithm),
                  let pat = StickerDatabase.pattern(for: c.id) else {
                mismatches.append(c.id)
                continue
            }
            if StickerDatabase.engineSideTopYellow(from: pat) != state.sideTopYellow {
                mismatches.append(c.id)
            }
            if state.sideTopYellow.contains(true) { anySideYellow = true }
            let sideColors = pat.frontTop + pat.rightTop + pat.backTop + pat.leftTop
            XCTAssertTrue(sideColors.allSatisfy { $0 == .yellow || $0 == .dark }, "\(c.id) OLL sides must be yellow/dark clues")
        }
        XCTAssertTrue(mismatches.isEmpty, "OLL side-clue mismatches: \(mismatches)")
        XCTAssertTrue(anySideYellow, "expected at least one OLL with yellow side stickers")
    }

    func testPLLPatternsUseRealFaceColors() {
        var mismatches: [String] = []
        for c in AlgorithmDatabase.pllCases {
            guard let state = CubeEngine.recognitionState(alg: c.primaryAlgorithm),
                  let pat = StickerDatabase.pattern(for: c.id) else {
                mismatches.append(c.id)
                continue
            }
            XCTAssertTrue(pat.uFace.allSatisfy { $0 == .yellow }, "\(c.id) PLL U must be yellow")
            let expected = StickerDatabase.displayPattern(from: state, ollOrientationMask: false)
            if pat != expected {
                mismatches.append(c.id)
            }
            let sides = pat.frontTop + pat.rightTop + pat.backTop + pat.leftTop
            XCTAssertTrue(sides.contains { $0 != .dark && $0 != .yellow }, "\(c.id) PLL sides must show real face colors")
        }
        XCTAssertTrue(mismatches.isEmpty, "PLL mismatches: \(mismatches)")
    }

    func testF2LPatternsUseNormalizedInverseNotInventedLastLayer() {
        var mismatches: [String] = []
        for c in F2LDatabase.f2lCases {
            XCTAssertNotNil(try? CubeEngine.parse(c.primaryAlgorithm), c.id)
            let state = CubeEngine.applyingNormalizedInverse(c.primaryAlgorithm)
            guard let pat = StickerDatabase.pattern(for: c.id) else {
                mismatches.append("\(c.id) missing")
                continue
            }
            let expected = StickerDatabase.displayPattern(from: state, ollOrientationMask: false)
            if pat != expected {
                mismatches.append(c.id)
            }
        }
        XCTAssertTrue(mismatches.isEmpty, "F2L inverse mismatches: \(mismatches)")
    }

    func testCrossLayoutReversesBackAndRightEngineRows() {
        let cube = CubeEngine.stateFromPattern(
            uFace: Array(repeating: true, count: 9),
            frontTop: [.red, .yellow, .red],
            rightTop: [.green, .yellow, .blue],
            backTop: [.orange, .yellow, .red],
            leftTop: [.blue, .yellow, .green]
        )
        let pat = StickerDatabase.displayPattern(from: cube, ollOrientationMask: false)
        XCTAssertEqual(pat.frontTop, [.red, .yellow, .red])
        XCTAssertEqual(pat.leftTop, [.blue, .yellow, .green])
        XCTAssertEqual(pat.rightTop, [.blue, .yellow, .green])
        XCTAssertEqual(pat.backTop, [.red, .yellow, .orange])
    }

    func testUnknownAndInvalidCasesAreUnavailableNeverHeuristic() {
        let invalid = dummyCase(type: "OLL", number: 999, alg: "NOT_A_MOVE")
        XCTAssertNil(StickerDatabase.pattern(for: invalid))
        XCTAssertNil(StickerDatabase.pattern(for: "OLL-999"))
        let view = CubeStateView(currentCase: invalid, visualMode: .preExecution, sizeMode: .medium)
        XCTAssertTrue(view.isUnavailable)
        XCTAssertNil(view.displayPattern)

        let unknownType = dummyCase(type: "ZBLL", number: 1, alg: "R U R' U'")
        XCTAssertNil(StickerDatabase.pattern(for: unknownType))
        XCTAssertTrue(CubeStateView(currentCase: unknownType, visualMode: .preExecution, sizeMode: .compact).isUnavailable)
    }

    func testCubeStateOverrideDrawsRealColorsWithoutOLLMask() {
        let oll = AlgorithmDatabase.ollCases[0]
        guard let rec = CubeEngine.recognitionState(alg: oll.primaryAlgorithm) else {
            return XCTFail("missing recognition state for \(oll.id)")
        }
        let masked = StickerDatabase.pattern(for: oll)
        let unmasked = StickerDatabase.displayPattern(from: rec, ollOrientationMask: false)
        XCTAssertNotNil(masked)
        XCTAssertNotEqual(masked, unmasked, "OLL mask should differ from real colors")

        let override = CubeStateView(
            currentCase: oll,
            visualMode: .preExecution,
            sizeMode: .large,
            cubeState: rec
        )
        XCTAssertEqual(override.displayPattern, unmasked)
        XCTAssertFalse(override.isUnavailable)

        let existing = CubeStateView(currentCase: oll, visualMode: .preExecution, sizeMode: .large)
        XCTAssertEqual(existing.displayPattern, masked)
    }

    func testPlaybackDoesNotMaskWhiteDownFaceStickers() {
        let cube = CubeEngine.applying("x2")
        let pattern = StickerDatabase.displayPattern(from: cube, ollOrientationMask: false)
        XCTAssertFalse(pattern.uFace.contains(.dark), "White face is real playback data, not an unknown/masked sticker")
        let masked = StickerDatabase.displayPattern(from: cube, ollOrientationMask: true)
        XCTAssertTrue(masked.uFace.allSatisfy { $0 == .dark })
    }

    func testExistingInitializerStillResolvesCachedCasePattern() {
        let pll = AlgorithmDatabase.pllCases[0]
        let view = CubeStateView(currentCase: pll, visualMode: .preExecution, sizeMode: .compact, uFaceOnly: false)
        XCTAssertEqual(view.displayPattern, StickerDatabase.pattern(for: pll))
        XCTAssertFalse(view.isUnavailable)
    }
}
