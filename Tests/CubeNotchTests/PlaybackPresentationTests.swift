import XCTest
@testable import CubeNotch

final class PlaybackPresentationTests: XCTestCase {
    func testValidAlgorithmShowsDiagramAndLiveNotation() {
        let presentation = PlaybackPresentation(
            visualMode: .preExecution,
            loadError: nil,
            reduceMotion: false,
            hasLoadedPlayback: true
        )
        XCTAssertTrue(presentation.showsDiagram)
        XCTAssertNil(presentation.errorMessage)
        XCTAssertTrue(presentation.showsLiveNotation)
        XCTAssertTrue(presentation.showsTransport)
        XCTAssertEqual(presentation.diagramAnimationDuration, 0.12)
    }

    func testTextOnlyHidesDiagramEvenWhenAlgorithmIsValid() {
        let presentation = PlaybackPresentation(
            visualMode: .textOnly,
            loadError: nil,
            reduceMotion: false,
            hasLoadedPlayback: true
        )
        XCTAssertFalse(presentation.showsDiagram)
        XCTAssertNil(presentation.errorMessage)
        XCTAssertTrue(presentation.showsLiveNotation)
    }

    func testInvalidTokenHidesDiagramAndSurfacesTheToken() {
        let presentation = PlaybackPresentation(
            visualMode: .preExecution,
            loadError: .invalidToken("Q"),
            reduceMotion: false,
            hasLoadedPlayback: false
        )
        XCTAssertFalse(presentation.showsDiagram)
        XCTAssertEqual(presentation.errorMessage, "Invalid move “Q”.")
        XCTAssertFalse(presentation.showsLiveNotation)
        XCTAssertFalse(presentation.showsTransport)
        XCTAssertNil(presentation.diagramAnimationDuration)
    }

    func testEmptyAlgorithmHidesDiagramWithVisibleError() {
        let presentation = PlaybackPresentation(
            visualMode: .setup,
            loadError: .emptyAlgorithm,
            reduceMotion: false,
            hasLoadedPlayback: false
        )
        XCTAssertFalse(presentation.showsDiagram)
        XCTAssertEqual(presentation.errorMessage, "Algorithm is empty.")
        XCTAssertFalse(presentation.showsLiveNotation)
    }

    func testReduceMotionDisablesDiagramTween() {
        let reduced = PlaybackPresentation(
            visualMode: .preExecution,
            loadError: nil,
            reduceMotion: true,
            hasLoadedPlayback: true
        )
        XCTAssertTrue(reduced.showsDiagram)
        XCTAssertNil(reduced.diagramAnimationDuration)
    }

    func testIdleOrFailedLoadNeverShowsSolvedDiagram() {
        let idle = PlaybackPresentation(
            visualMode: .preExecution,
            loadError: nil,
            reduceMotion: false,
            hasLoadedPlayback: false
        )
        XCTAssertFalse(idle.showsDiagram, "Unloaded playback must not draw the animator's solved reset cube")
        XCTAssertFalse(idle.showsLiveNotation)
        XCTAssertFalse(idle.showsTransport)

        let failed = PlaybackPresentation(
            visualMode: .preExecution,
            loadError: .invalidToken("Q"),
            reduceMotion: false,
            hasLoadedPlayback: false
        )
        XCTAssertFalse(failed.showsDiagram)
        XCTAssertNotNil(failed.errorMessage)
    }

    func testNilCubeStateIsNotTheErrorPath() {
        XCTAssertTrue(
            PlaybackPresentation.gatesDiagramOnSuccessfulLoad,
            "CubeStateView treats nil cubeState as a valid case-recognition diagram; hide the view instead"
        )
    }

    func testStandaloneNotationIsOmittedWhenPlaybackAlreadyShowsIt() {
        XCTAssertFalse(CaseDetailCopyPolicy.showsStandaloneNotation(playbackShowsLiveNotation: true))
        XCTAssertTrue(CaseDetailCopyPolicy.showsStandaloneNotation(playbackShowsLiveNotation: false))
    }
}
