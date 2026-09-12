import XCTest
import Combine
@testable import CubeNotch

final class AlgorithmAnimatorTests: XCTestCase {

    private func makeAnimator() -> AlgorithmAnimator {
        AlgorithmAnimator(tickSource: .manual)
    }

    private func literalInverseStart(_ alg: String) -> CubeEngine {
        let parsed = try! CubeEngine.parse(alg)
        var cube = CubeEngine()
        for token in parsed.reversed() {
            cube.apply(token: (token.base, token.turns == 1 ? 3 : (token.turns == 3 ? 1 : 2)))
        }
        return cube
    }

    func testWhitespaceSeparatedPlaybackCompletesEveryParsedMove() throws {
        let animator = makeAnimator()
        try animator.load("R\tU2\nRw'")
        XCTAssertEqual(animator.notationTokens, ["R", "U2", "Rw'"])
        animator.play()
        for _ in 0..<3 { animator.tick() }
        XCTAssertEqual(animator.currentIndex, 3)
        XCTAssertEqual(animator.progress, 1)
        XCTAssertTrue(animator.cube.isSolved)
        XCTAssertFalse(animator.isPlaying)
    }

    func testAutomaticPlaybackRunsOnMainLoopAndStopsAtCompletion() throws {
        let animator = AlgorithmAnimator()
        animator.speed = 3
        try animator.load("R U")
        let completed = expectation(description: "Automatic playback completed")
        let subscription = animator.$isPlaying.dropFirst().sink { playing in
            if !playing && animator.isFinished {
                XCTAssertTrue(Thread.isMainThread)
                completed.fulfill()
            }
        }
        animator.play()
        wait(for: [completed], timeout: 3)
        withExtendedLifetime(subscription) {}
        XCTAssertTrue(animator.cube.isSolved)
        XCTAssertEqual(animator.currentIndex, 2)
    }

    func testEveryPrimaryAlgorithmPlaybackReachesSolved() throws {
        for cubeCase in AlgorithmDatabase.ollCases + AlgorithmDatabase.pllCases + F2LDatabase.f2lCases {
            let animator = makeAnimator()
            try animator.load(cubeCase.primaryAlgorithm)
            for _ in animator.notationTokens { animator.step() }
            XCTAssertTrue(animator.cube.isSolved, cubeCase.id)
            XCTAssertTrue(animator.isFinished, cubeCase.id)
        }
    }

    func testLoadUsesStrictParseAndStartsAtLiteralInverse() throws {
        let animator = makeAnimator()
        try animator.load("R")

        XCTAssertEqual(animator.notationTokens, ["R"])
        XCTAssertEqual(animator.currentIndex, 0)
        XCTAssertFalse(animator.isPlaying)
        XCTAssertFalse(animator.cube.isSolved)
        XCTAssertEqual(animator.cube, CubeEngine.applying("R'"))
        XCTAssertEqual(animator.cube.stickers, literalInverseStart("R").stickers)
    }

    func testForwardStepsReachSolvedAndHighlightCurrentMove() throws {
        let animator = makeAnimator()
        try animator.load("R U R' U'")

        XCTAssertEqual(animator.notationTokens, ["R", "U", "R'", "U'"])
        XCTAssertEqual(animator.currentMoveNotation, "R")
        XCTAssertEqual(animator.progress, 0)

        animator.step()
        XCTAssertEqual(animator.currentIndex, 1)
        XCTAssertEqual(animator.currentMoveNotation, "U")
        XCTAssertEqual(animator.cube, CubeEngine.applying("R", to: literalInverseStart("R U R' U'")))
        XCTAssertFalse(animator.cube.isSolved)

        animator.step()
        animator.step()
        animator.step()
        XCTAssertTrue(animator.cube.isSolved)
        XCTAssertTrue(animator.isFinished)
        XCTAssertNil(animator.currentMoveNotation)
        XCTAssertEqual(animator.progress, 1.0)

        animator.step()
        XCTAssertTrue(animator.cube.isSolved)
        XCTAssertEqual(animator.currentIndex, 4)
    }

    func testLoadRejectsInvalidTokenWithoutFabricatingState() {
        let animator = makeAnimator()
        XCTAssertThrowsError(try animator.load("R U Q")) { error in
            XCTAssertEqual(error as? AlgorithmAnimator.LoadError, .invalidToken("Q"))
        }
        XCTAssertEqual(animator.loadError, .invalidToken("Q"))
        XCTAssertTrue(animator.cube.isSolved)
        XCTAssertTrue(animator.notationTokens.isEmpty)
    }

    func testInvalidReloadClearsPreviousPlayback() throws {
        let animator = makeAnimator()
        try animator.load("R U")
        animator.step()
        XCTAssertThrowsError(try animator.load("R U Q"))
        XCTAssertTrue(animator.notationTokens.isEmpty)
        XCTAssertEqual(animator.currentIndex, 0)
        XCTAssertTrue(animator.cube.isSolved)
        XCTAssertFalse(animator.isPlaying)
    }

    func testLoadRejectsEmptyAlgorithm() {
        let animator = makeAnimator()
        XCTAssertThrowsError(try animator.load("   ")) { error in
            XCTAssertEqual(error as? AlgorithmAnimator.LoadError, .emptyAlgorithm)
        }
        XCTAssertEqual(animator.loadError, .emptyAlgorithm)
    }

    func testManualTickAdvancesOnlyWhilePlaying() throws {
        let animator = makeAnimator()
        try animator.load("R U")

        animator.tick()
        XCTAssertEqual(animator.currentIndex, 0)

        animator.play()
        XCTAssertTrue(animator.isPlaying)
        animator.tick()
        XCTAssertEqual(animator.currentIndex, 1)
        XCTAssertEqual(animator.currentMoveNotation, "U")

        animator.pause()
        XCTAssertFalse(animator.isPlaying)
        animator.tick()
        XCTAssertEqual(animator.currentIndex, 1)

        animator.play()
        animator.tick()
        XCTAssertTrue(animator.cube.isSolved)
        XCTAssertFalse(animator.isPlaying)
        XCTAssertTrue(animator.isFinished)
    }

    func testResetReturnsToLiteralInverseAndStops() throws {
        let animator = makeAnimator()
        try animator.load("R U R'")
        animator.play()
        animator.tick()
        animator.tick()
        XCTAssertEqual(animator.currentIndex, 2)

        animator.reset()
        XCTAssertFalse(animator.isPlaying)
        XCTAssertEqual(animator.currentIndex, 0)
        XCTAssertEqual(animator.cube.stickers, literalInverseStart("R U R'").stickers)
    }

    func testStopCancelsPlaybackWithoutResettingCube() throws {
        let animator = makeAnimator()
        try animator.load("R U")
        animator.play()
        animator.tick()
        let mid = animator.cube

        animator.stop()
        XCTAssertFalse(animator.isPlaying)
        XCTAssertEqual(animator.cube, mid)
        XCTAssertEqual(animator.currentIndex, 1)
        animator.tick()
        XCTAssertEqual(animator.currentIndex, 1)
    }

    func testSpeedClampsToSupportedRange() {
        let animator = makeAnimator()
        animator.speed = 0.1
        XCTAssertEqual(animator.speed, 0.5)
        animator.speed = 9
        XCTAssertEqual(animator.speed, 3.0)
        animator.speed = 1.5
        XCTAssertEqual(animator.speed, 1.5)
        XCTAssertEqual(animator.moveInterval, 0.4 / 1.5, accuracy: 0.0001)
    }

    func testLoadingANewAlgorithmStopsAndRebuildsFromLiteralInverse() throws {
        let animator = makeAnimator()
        try animator.load("R U")
        animator.play()
        animator.tick()

        try animator.load("F")
        XCTAssertFalse(animator.isPlaying)
        XCTAssertEqual(animator.notationTokens, ["F"])
        XCTAssertEqual(animator.currentIndex, 0)
        XCTAssertEqual(animator.cube.stickers, literalInverseStart("F").stickers)
        animator.step()
        XCTAssertTrue(animator.cube.isSolved)
    }

    func testTPermLiteralPlaybackReachesSolved() throws {
        let alg = "R U R' U' R' F R2 U' R' U' R U R' F'"
        let animator = makeAnimator()
        try animator.load(alg)
        XCTAssertEqual(animator.cube.stickers, literalInverseStart(alg).stickers)

        while !animator.isFinished {
            animator.step()
        }
        XCTAssertTrue(animator.cube.isSolved)
        XCTAssertEqual(animator.currentIndex, animator.notationTokens.count)
    }
}
