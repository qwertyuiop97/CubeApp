import XCTest
@testable import CubeNotch

final class LaunchAtLoginTests: XCTestCase {
    func testFailedRegistrationKeepsActualDisabledStateAndReportsError() {
        let service = FakeLaunchAtLoginService(enabled: false, error: FakeLaunchAtLoginError.denied)
        let result = LaunchAtLogin.apply(true, using: service)

        XCTAssertEqual(service.setEnabledCalls, [true])
        XCTAssertFalse(result.isEnabled)
        XCTAssertFalse(service.isEnabled)
        XCTAssertEqual(result.errorMessage, "Couldn’t update launch at login.")
    }

    func testSuccessfulRegistrationPersistsEnabledState() {
        let service = FakeLaunchAtLoginService(enabled: false)
        let result = LaunchAtLogin.apply(true, using: service)

        XCTAssertEqual(service.setEnabledCalls, [true])
        XCTAssertTrue(result.isEnabled)
        XCTAssertTrue(service.isEnabled)
        XCTAssertNil(result.errorMessage)
    }

    func testFailedUnregisterKeepsEnabledStateAndReportsError() {
        let service = FakeLaunchAtLoginService(enabled: true, error: FakeLaunchAtLoginError.denied)
        let result = LaunchAtLogin.apply(false, using: service)

        XCTAssertEqual(service.setEnabledCalls, [false])
        XCTAssertTrue(result.isEnabled)
        XCTAssertTrue(service.isEnabled)
        XCTAssertEqual(result.errorMessage, "Couldn’t update launch at login.")
    }

    func testSuccessfulUnregisterPersistsDisabledState() {
        let service = FakeLaunchAtLoginService(enabled: true)
        let result = LaunchAtLogin.apply(false, using: service)

        XCTAssertEqual(service.setEnabledCalls, [false])
        XCTAssertFalse(result.isEnabled)
        XCTAssertFalse(service.isEnabled)
        XCTAssertNil(result.errorMessage)
    }
}

private enum FakeLaunchAtLoginError: Error {
    case denied
}

private final class FakeLaunchAtLoginService: LaunchAtLoginServicing {
    var enabled: Bool
    var error: Error?
    private(set) var setEnabledCalls: [Bool] = []

    init(enabled: Bool, error: Error? = nil) {
        self.enabled = enabled
        self.error = error
    }

    var isEnabled: Bool { enabled }

    func setEnabled(_ enabled: Bool) throws {
        setEnabledCalls.append(enabled)
        if let error {
            throw error
        }
        self.enabled = enabled
    }
}
