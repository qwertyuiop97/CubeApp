import XCTest
@testable import CubeNotch

final class OverlayDismissalTests: XCTestCase {
    func testReduceMotionChangesHowTheOverlayHidesNotWhetherItHides() {
        XCTAssertEqual(OverlayDismissal.kind(reduceMotion: false), .animated)
        XCTAssertEqual(OverlayDismissal.kind(reduceMotion: true), .immediate)
    }

    func testRequestPostsTheHideNotificationMatchingTheKind() {
        var received: [Notification.Name] = []
        let animated = NotificationCenter.default.addObserver(
            forName: .requestAnimatedHide, object: nil, queue: nil
        ) { _ in received.append(.requestAnimatedHide) }
        let immediate = NotificationCenter.default.addObserver(
            forName: .requestImmediateHide, object: nil, queue: nil
        ) { _ in received.append(.requestImmediateHide) }
        defer {
            NotificationCenter.default.removeObserver(animated)
            NotificationCenter.default.removeObserver(immediate)
        }

        OverlayDismissal.request(reduceMotion: false)
        OverlayDismissal.request(reduceMotion: true)

        XCTAssertEqual(received, [.requestAnimatedHide, .requestImmediateHide])
    }
}
