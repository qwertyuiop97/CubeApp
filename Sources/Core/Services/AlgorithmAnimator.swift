import Foundation
import Combine

/// Move-by-move playback over a real `CubeEngine` state.
/// Setup is the exact literal inverse of a strictly parsed algorithm; each
/// forward token is applied as-is. No color interpolation lives here.
public final class AlgorithmAnimator: ObservableObject {
    public enum TickSource: Equatable {
        case automatic
        case manual
    }

    public enum LoadError: Error, Equatable {
        case emptyAlgorithm
        case invalidToken(String)
    }

    public let tickSource: TickSource

    @Published public private(set) var cube: CubeEngine = CubeEngine()
    @Published public private(set) var notationTokens: [String] = []
    @Published public private(set) var currentIndex: Int = 0
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var loadError: LoadError?
    @Published public var speed: Double = 1.0 {
        didSet {
            let clamped = min(3.0, max(0.5, speed))
            if clamped != speed {
                speed = clamped
                return
            }
            if isPlaying, tickSource == .automatic {
                startTimer()
            }
        }
    }

    private var parsedTokens: [(base: Character, turns: Int)] = []
    private var startCube: CubeEngine = CubeEngine()
    private var timer: Timer?

    public init(tickSource: TickSource = .automatic) {
        self.tickSource = tickSource
    }

    deinit {
        timer?.invalidate()
    }

    public var progress: Double {
        guard !notationTokens.isEmpty else { return 0 }
        return Double(currentIndex) / Double(notationTokens.count)
    }

    public var currentMoveNotation: String? {
        guard currentIndex >= 0, currentIndex < notationTokens.count else { return nil }
        return notationTokens[currentIndex]
    }

    public var isFinished: Bool {
        !notationTokens.isEmpty && currentIndex >= notationTokens.count
    }

    public func load(_ algorithm: String) throws {
        stopTimer()
        isPlaying = false
        loadError = nil
        do {
            let parsed = try CubeEngine.parse(algorithm)
            let parts = algorithm
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .split(whereSeparator: { $0.isWhitespace })
                .map(String.init)
            parsedTokens = parsed
            notationTokens = parts
            var start = CubeEngine()
            for token in parsed.reversed() {
                start.apply(token: (token.base, invertTurns(token.turns)))
            }
            startCube = start
            cube = start
            currentIndex = 0
        } catch CubeEngine.ParseError.emptyAlgorithm {
            clearPlayback()
            loadError = .emptyAlgorithm
            throw LoadError.emptyAlgorithm
        } catch CubeEngine.ParseError.invalidToken(let token) {
            clearPlayback()
            loadError = .invalidToken(token)
            throw LoadError.invalidToken(token)
        }
    }

    public func step() {
        guard currentIndex < parsedTokens.count else { return }
        cube.apply(token: parsedTokens[currentIndex])
        currentIndex += 1
        if isFinished {
            isPlaying = false
            stopTimer()
        }
    }

    public func play() {
        guard !parsedTokens.isEmpty, !isFinished else { return }
        isPlaying = true
        if tickSource == .automatic {
            startTimer()
        }
    }

    public func pause() {
        isPlaying = false
        stopTimer()
    }

    public func reset() {
        isPlaying = false
        stopTimer()
        cube = startCube
        currentIndex = 0
    }

    public func stop() {
        isPlaying = false
        stopTimer()
    }

    /// Advance one move when playing. Tests with `.manual` tick source call this
    /// explicitly; automatic playback uses a Timer that invokes the same path.
    public func tick() {
        guard isPlaying else { return }
        step()
    }

    public var moveInterval: TimeInterval {
        0.4 / speed
    }

    private func invertTurns(_ t: Int) -> Int {
        t == 1 ? 3 : (t == 3 ? 1 : 2)
    }

    private func clearPlayback() {
        parsedTokens = []
        notationTokens = []
        startCube = CubeEngine()
        cube = CubeEngine()
        currentIndex = 0
    }

    private func startTimer() {
        stopTimer()
        let t = Timer(timeInterval: moveInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
