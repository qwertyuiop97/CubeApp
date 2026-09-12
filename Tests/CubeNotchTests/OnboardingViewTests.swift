import SwiftUI
import XCTest
@testable import CubeNotch

final class OnboardingViewTests: XCTestCase {
    func testHUDPageDoesNotClaimNeverStealsFocus() {
        let body = OnboardingContent.pages[0].body
        XCTAssertFalse(body.localizedCaseInsensitiveContains("never steals focus"))
        XCTAssertTrue(body.localizedCaseInsensitiveContains("does not take focus"))
        XCTAssertTrue(body.localizedCaseInsensitiveContains("recording a shortcut"))
    }

    func testScrollSelectionBindingWritesExistingPageIndex() {
        var page = 0
        let currentPage = Binding(get: { page }, set: { page = $0 })
        let selection = OnboardingPageSelection.boundIndex(currentPage)

        selection.wrappedValue = 2

        XCTAssertEqual(page, 2)
        XCTAssertEqual(selection.wrappedValue, 2)
    }

    func testNilScrollSelectionLeavesExistingPageIndex() {
        var page = 1
        let currentPage = Binding(get: { page }, set: { page = $0 })
        let selection = OnboardingPageSelection.boundIndex(currentPage)

        selection.wrappedValue = nil

        XCTAssertEqual(page, 1)
        XCTAssertEqual(selection.wrappedValue, 1)
    }
}
