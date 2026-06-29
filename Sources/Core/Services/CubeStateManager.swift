import Foundation
import Observation

public enum SizeMode: String, CaseIterable, Codable {
    case compact
    case medium
    case large
}

public enum VisualMode: String, CaseIterable, Codable {
    case preExecution
    case setup
    case textOnly
}

public enum Anchor: String, CaseIterable, Codable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case notch
    case bottomCenter
}

extension Notification.Name {
    static let cubeStateDidChange = Notification.Name("cubeStateDidChange")
    static let requestAnimatedHide = Notification.Name("requestAnimatedHide")
    static let requestHotkeyRebind = Notification.Name("requestHotkeyRebind")
    static let requestAccessibilityPrompt = Notification.Name("requestAccessibilityPrompt")
    static let requestRetryEventTap = Notification.Name("requestRetryEventTap")
    static let accessibilityPermissionGranted = Notification.Name("accessibilityPermissionGranted")
}

@Observable
public final class CubeStateManager {
    public var currentCase: CubeCase
    public var sizeMode: SizeMode = .medium {
        didSet { NotificationCenter.default.post(name: .cubeStateDidChange, object: nil) }
    }
    public var visualMode: VisualMode = .preExecution {
        didSet { NotificationCenter.default.post(name: .cubeStateDidChange, object: nil) }
    }
    public var anchorPosition: Anchor = .topRight {
        didSet { NotificationCenter.default.post(name: .cubeStateDidChange, object: nil) }
    }
    public var followActiveScreen: Bool = false {
        didSet { NotificationCenter.default.post(name: .cubeStateDidChange, object: nil) }
    }
    public var preferredScreenName: String = "" {
        didSet { NotificationCenter.default.post(name: .cubeStateDidChange, object: nil) }
    }

    private let allCases: [CubeCase]
    private var currentIndex: Int = 0

    public init() {
        allCases = AlgorithmDatabase.ollCases + AlgorithmDatabase.pllCases
        currentCase = allCases[0]
    }

    public var currentMoves: [String] {
        parseMoves(currentCase.primaryAlgorithm)
    }

    public func nextCase() {
        currentIndex = (currentIndex + 1) % allCases.count
        currentCase = allCases[currentIndex]
        NotificationCenter.default.post(name: .cubeStateDidChange, object: nil)
    }

    public func previousCase() {
        currentIndex = (currentIndex - 1 + allCases.count) % allCases.count
        currentCase = allCases[currentIndex]
        NotificationCenter.default.post(name: .cubeStateDidChange, object: nil)
    }

    public func randomCase() {
        currentIndex = Int.random(in: 0..<allCases.count)
        currentCase = allCases[currentIndex]
        NotificationCenter.default.post(name: .cubeStateDidChange, object: nil)
    }

    public func setSizeMode(_ mode: SizeMode) {
        sizeMode = mode
    }

    public func setVisualMode(_ mode: VisualMode) {
        visualMode = mode
    }

    public func setAnchor(_ anchor: Anchor) {
        anchorPosition = anchor
    }

    public func setFollowActiveScreen(_ value: Bool) {
        followActiveScreen = value
    }

    public func setPreferredScreenName(_ name: String) {
        preferredScreenName = name
    }

    public func selectCase(_ c: CubeCase) {
        if let idx = allCases.firstIndex(where: { $0.id == c.id }) {
            currentIndex = idx
        }
        currentCase = c
        NotificationCenter.default.post(name: .cubeStateDidChange, object: nil)
    }

    private func parseMoves(_ algorithm: String) -> [String] {
        algorithm.split(separator: " ").map(String.init).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}

extension SizeMode {
    var windowSize: NSSize {
        switch self {
        case .compact: return NSSize(width: 240, height: 300)
        case .medium:  return NSSize(width: 340, height: 440)
        case .large:   return NSSize(width: 440, height: 540)
        }
    }
}
