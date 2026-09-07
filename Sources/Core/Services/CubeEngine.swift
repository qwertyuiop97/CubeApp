import Foundation

/// A real 3x3 cube state model: 54 facelets, correct move mechanics.
///
/// Facelet layout (indices), each face row-major as seen looking at that face:
///   U 0-8, R 9-17, F 18-26, D 27-35, L 36-44, B 45-53
/// Corner reference positions: U0=UBL U2=UBR U6=UFL U8=UFR (Kociemba-compatible).
/// `stickers[i]` holds the index of the facelet that originally sat at position i,
/// so a solved cube is `stickers[i] == i` and piece identity is derivable from face sets.
///
/// Supported notation: U D R L F B, M E S, x y z, wide u d r l f b —
/// each with ', 2, and 2' suffixes (2' == 2).
public struct CubeEngine: Equatable {
    public private(set) var stickers: [Int]

    // MARK: - Init

    public init() {
        stickers = Array(0..<54)
    }

    public init(stickers: [Int]) {
        precondition(stickers.count == 54, "CubeEngine needs 54 facelets")
        self.stickers = stickers
    }

    // MARK: - Move tables (content-flow cycles: a -> b means content at a moves to b)

    private static let uCycles: [[Int]] = [[0, 2, 8, 6], [1, 5, 7, 3],
                                           [18, 36, 45, 9], [19, 37, 46, 10], [20, 38, 47, 11]]
    private static let dCycles: [[Int]] = [[27, 29, 35, 33], [28, 32, 34, 30],
                                           [24, 15, 51, 42], [25, 16, 52, 43], [26, 17, 53, 44]]
    private static let rCycles: [[Int]] = [[9, 11, 17, 15], [10, 14, 16, 12],
                                           [20, 2, 51, 29], [23, 5, 48, 32], [26, 8, 45, 35]]
    private static let lCycles: [[Int]] = [[36, 38, 44, 42], [37, 41, 43, 39],
                                           [0, 18, 27, 53], [6, 24, 33, 47], [3, 21, 30, 50]]
    private static let fCycles: [[Int]] = [[18, 20, 26, 24], [19, 23, 25, 21],
                                           [38, 8, 15, 27], [41, 7, 12, 28], [44, 6, 9, 29]]
    private static let bCycles: [[Int]] = [[45, 47, 53, 51], [46, 50, 52, 48],
                                           [2, 36, 33, 17], [0, 42, 35, 11], [1, 39, 34, 14]]
    private static let mCycles: [[Int]] = [[7, 25, 34, 46], [1, 19, 28, 52], [4, 22, 31, 49]]
    private static let eCycles: [[Int]] = [[21, 12, 48, 39], [23, 14, 50, 41], [22, 13, 49, 40]]
    private static let sCycles: [[Int]] = [[3, 10, 32, 43], [5, 16, 30, 37], [4, 13, 31, 40]]
    private static let xCycles: [[Int]] = [[9, 11, 17, 15], [10, 14, 16, 12],
                                           [36, 42, 44, 38], [37, 39, 43, 41],
                                           [0, 53, 27, 18], [1, 52, 28, 19], [2, 51, 29, 20],
                                           [3, 50, 30, 21], [5, 48, 32, 23], [6, 47, 33, 24],
                                           [7, 46, 34, 25], [8, 45, 35, 26], [4, 49, 31, 22]]
    private static let yCycles: [[Int]] = [[0, 2, 8, 6], [1, 5, 7, 3],
                                           [18, 36, 45, 9], [19, 37, 46, 10], [20, 38, 47, 11],
                                           [21, 39, 48, 12], [23, 41, 50, 14],
                                           [27, 33, 35, 29], [28, 30, 34, 32],
                                           [24, 42, 51, 15], [26, 44, 53, 17], [25, 43, 52, 16],
                                           [22, 40, 49, 13]]
    private static let zCycles: [[Int]] = [[18, 20, 26, 24], [19, 23, 25, 21],
                                           [45, 51, 53, 47], [46, 48, 52, 50],
                                           [0, 11, 35, 42], [1, 14, 34, 39], [2, 17, 33, 36],
                                           [3, 10, 32, 43], [5, 16, 30, 37], [6, 9, 29, 44],
                                           [7, 12, 28, 41], [8, 15, 27, 38], [4, 13, 31, 40]]

    /// Base move -> cycles. Wide moves are compositions of two base moves.
    private static func cycles(forBase base: Character) -> [[Int]]? {
        switch base {
        case "U": return uCycles
        case "D": return dCycles
        case "R": return rCycles
        case "L": return lCycles
        case "F": return fCycles
        case "B": return bCycles
        case "M": return mCycles
        case "E": return eCycles
        case "S": return sCycles
        case "x": return xCycles
        case "y": return yCycles
        case "z": return zCycles
        default: return nil
        }
    }

    // MARK: - Parsing / applying

    public enum ParseError: Error, Equatable {
        case invalidToken(String)
        case emptyAlgorithm
    }

    /// Wide moves (u d r l f b) are handled in apply(token:) as face+slice compositions.
    private static func isKnownBase(_ base: Character) -> Bool {
        cycles(forBase: base) != nil || "udrlfb".contains(base)
    }

    /// Tokenizes standard notation. Returns tokens as (base, turns) where turns is 1..3
    /// (1 = clockwise, 2 = half, 3 = counter-clockwise).
    public static func tokenize(_ alg: String) -> [(base: Character, turns: Int)] {
        var tokens: [(Character, Int)] = []
        let trimmed = alg.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        for raw in trimmed.split(separator: " ") {
            let token = String(raw)
            guard let base = token.first, isKnownBase(base) else { continue } // unknown tokens skipped by callers if desired
            var turns = 1
            let rest = token.dropFirst()
            if rest.contains("2") { turns = 2 }
            if rest.hasSuffix("'") && turns == 1 { turns = 3 }
            tokens.append((base, turns))
        }
        return tokens
    }

    /// Strict parser: throws on any token that is not valid notation.
    public static func parse(_ alg: String) throws -> [(base: Character, turns: Int)] {
        let trimmed = alg.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ParseError.emptyAlgorithm }
        var tokens: [(Character, Int)] = []
        for raw in trimmed.split(separator: " ") {
            let token = String(raw)
            guard let first = token.first, isKnownBase(first) else {
                throw ParseError.invalidToken(token)
            }
            let rest = String(token.dropFirst())
            var turns = 1
            var checked = rest
            if checked.hasPrefix("2") {
                turns = 2
                checked = String(checked.dropFirst())
            }
            if checked == "'" {
                if turns == 1 { turns = 3 }
            } else if !checked.isEmpty {
                throw ParseError.invalidToken(token)
            }
            tokens.append((first, turns))
        }
        return tokens
    }

    public mutating func apply(token: (base: Character, turns: Int)) {
        switch token.base {
        case "u": applyBase("U", token.turns); applyBase("E", Self.invertTurns(token.turns))
        case "d": applyBase("D", token.turns); applyBase("E", token.turns)
        case "r": applyBase("R", token.turns); applyBase("M", Self.invertTurns(token.turns))
        case "l": applyBase("L", token.turns); applyBase("M", token.turns)
        case "f": applyBase("F", token.turns); applyBase("S", token.turns)
        case "b": applyBase("B", token.turns); applyBase("S", Self.invertTurns(token.turns))
        default: applyBase(token.base, token.turns)
        }
    }

    private static func invertTurns(_ t: Int) -> Int { t == 1 ? 3 : (t == 3 ? 1 : 2) }

    private mutating func applyBase(_ base: Character, _ turns: Int) {
        guard let cycles = Self.cycles(forBase: base) else { return }
        for _ in 0..<turns {
            var next = stickers
            for cycle in cycles {
                let n = cycle.count
                for i in 0..<n {
                    next[cycle[(i + 1) % n]] = stickers[cycle[i]]
                }
            }
            stickers = next
        }
    }

    public mutating func apply(_ alg: String) {
        for token in Self.tokenize(alg) { apply(token: token) }
    }

    // MARK: - Frame-normalized application

    /// Rewrites an algorithm into the pre-rotation frame: walks tokens forward,
    /// remaps every move through the accumulated x/y/z frame, drops the rotations.
    /// "y R" -> "B"; "R y" -> "R"; "R y U" -> "R U".
    private static func remappedTokens(_ alg: String) -> [(base: Character, turns: Int)] {
        var frame: [Character: (Character, Bool)] = [
            "U": ("U", false), "D": ("D", false), "R": ("R", false), "L": ("L", false),
            "F": ("F", false), "B": ("B", false),
            "M": ("M", false), "E": ("E", false), "S": ("S", false)
        ]
        let rotMaps: [Character: [Character: (Character, Bool)]] = [
            "y": ["F": ("R", false), "R": ("B", false), "B": ("L", false), "L": ("F", false),
                  "U": ("U", false), "D": ("D", false),
                  "M": ("S", false), "S": ("M", true), "E": ("E", false)],
            "x": ["F": ("D", false), "D": ("B", false), "B": ("U", false), "U": ("F", false),
                  "R": ("R", false), "L": ("L", false),
                  "M": ("M", false), "E": ("S", true), "S": ("E", false)],
            "z": ["U": ("L", false), "L": ("D", false), "D": ("R", false), "R": ("U", false),
                  "F": ("F", false), "B": ("B", false),
                  "M": ("E", false), "E": ("M", true), "S": ("S", false)]
        ]
        var out: [(Character, Int)] = []
        for token in tokenize(alg) {
            if let map = rotMaps[token.base] {
                for _ in 0..<token.turns {
                    var next: [Character: (Character, Bool)] = [:]
                    for (k, v) in frame {
                        let m = map[v.0]!
                        next[k] = (m.0, v.1 != m.1)
                    }
                    frame = next
                }
            } else {
                // Decompose wide moves into face+slice, remap each component.
                let components: [(Character, Int)]
                switch token.base {
                case "u": components = [("U", token.turns), ("E", invertTurns(token.turns))]
                case "d": components = [("D", token.turns), ("E", token.turns)]
                case "r": components = [("R", token.turns), ("M", invertTurns(token.turns))]
                case "l": components = [("L", token.turns), ("M", token.turns)]
                case "f": components = [("F", token.turns), ("S", token.turns)]
                case "b": components = [("B", token.turns), ("S", invertTurns(token.turns))]
                default: components = [(token.base, token.turns)]
                }
                for (base, turns) in components {
                    guard let (orig, flip) = frame[base] else { continue }
                    out.append((orig, flip ? invertTurns(turns) : turns))
                }
            }
        }
        return out
    }

    /// Applies an algorithm in the pre-rotation frame: x/y/z become frame changes
    /// (moves after them are remapped) instead of physically rotating the cube.
    /// The result equals the literal application followed by undoing the net rotation.
    public mutating func applyNormalized(_ alg: String) {
        for (base, turns) in Self.remappedTokens(alg) {
            applyBase(base, turns)
        }
    }

    /// Frame-normalized application from a start state.
    public static func applyingNormalized(_ alg: String, to start: CubeEngine = CubeEngine()) -> CubeEngine {
        var cube = start
        cube.applyNormalized(alg)
        return cube
    }

    /// Frame-normalized inverse: the recognition state an alg solves, expressed in
    /// the standard (pre-rotation) orientation. Trailing rotations cancel; leading
    /// rotations shift the case orientation accordingly.
    public static func applyingNormalizedInverse(_ alg: String, to start: CubeEngine = CubeEngine()) -> CubeEngine {
        var cube = start
        for (base, turns) in Self.remappedTokens(alg).reversed() {
            cube.applyBase(base, turns == 1 ? 3 : (turns == 3 ? 1 : 2))
        }
        return cube
    }

    public static func applying(_ alg: String, to start: CubeEngine = CubeEngine()) -> CubeEngine {
        var cube = start
        cube.apply(alg)
        return cube
    }

    public mutating func applyInverse(_ alg: String) {
        let tokens = Self.tokenize(alg)
        for token in tokens.reversed() {
            apply(token: (token.base, token.turns == 1 ? 3 : (token.turns == 3 ? 1 : 2)))
        }
    }

    public static func applyingInverse(_ alg: String, to start: CubeEngine = CubeEngine()) -> CubeEngine {
        var cube = start
        cube.applyInverse(alg)
        return cube
    }

    // MARK: - Piece analysis

    public enum Face: Int, CaseIterable {
        case up = 0, right, front, down, left, back
    }

    private static func face(of stickerIndex: Int) -> Face {
        Face(rawValue: stickerIndex / 9)!
    }

    /// Corner reference positions as facelet triples, ordered (U/D facelet, second, third).
    public static let cornerPositions: [String: [Int]] = [
        "UFR": [8, 9, 20], "UFL": [6, 18, 38], "ULB": [0, 36, 47], "UBR": [2, 45, 11],
        "DFR": [29, 26, 15], "DFL": [27, 44, 24], "DBL": [33, 53, 42], "DBR": [35, 17, 51]
    ]
    public static let cornerPositionOrder = ["UFR", "UFL", "ULB", "UBR", "DFR", "DFL", "DBL", "DBR"]

    /// Edge reference positions as facelet pairs.
    public static let edgePositions: [String: [Int]] = [
        "UF": [7, 19], "UR": [5, 10], "UL": [3, 37], "UB": [1, 46],
        "FR": [23, 12], "FL": [21, 41], "BL": [50, 39], "BR": [48, 14],
        "DF": [28, 25], "DR": [32, 16], "DB": [34, 52], "DL": [30, 43]
    ]
    public static let edgePositionOrder = ["UF", "UR", "UL", "UB", "FR", "FL", "BL", "BR", "DF", "DR", "DB", "DL"]

    /// Identity of the piece at a position: sorted face-set of its stickers' home faces.
    private static func pieceKey(_ cube: CubeEngine, facelets: [Int]) -> [Int] {
        facelets.map { Face(rawValue: cube.stickers[$0] / 9)!.rawValue }.sorted()
    }

    /// For each named position, the sorted face-set of the piece currently there.
    public func cornerOccupancy() -> [String: [Int]] {
        var result: [String: [Int]] = [:]
        for (name, facelets) in Self.cornerPositions { result[name] = Self.pieceKey(self, facelets: facelets) }
        return result
    }

    public func edgeOccupancy() -> [String: [Int]] {
        var result: [String: [Int]] = [:]
        for (name, facelets) in Self.edgePositions { result[name] = Self.pieceKey(self, facelets: facelets) }
        return result
    }

    /// True when every piece belongs in its current position (cube solved).
    public var isSolved: Bool {
        stickers == Array(0..<54)
    }

    /// True when every F2L piece (D-layer corners + middle-layer edges) is home,
    /// regardless of the U layer or sticker orientation within a piece.
    public var f2lPiecesHome: Bool {
        let expectedCorners = ["DFR": [1, 2, 3], "DFL": [2, 3, 4], "DBL": [3, 4, 5], "DBR": [1, 3, 5]]
        let expectedEdges = ["FR": [1, 2], "FL": [2, 4], "BL": [4, 5], "BR": [1, 5],
                             "DF": [2, 3], "DR": [1, 3], "DB": [3, 5], "DL": [3, 4]]
        let co = cornerOccupancy(), eo = edgeOccupancy()
        return expectedCorners.allSatisfy { co[$0.key] == $0.value }
            && expectedEdges.allSatisfy { eo[$0.key] == $0.value }
    }

    /// True when the first two layers are restored (PLL precondition): every facelet
    /// outside the U face and the side top rows is home.
    public var firstTwoLayersSolved: Bool {
        let staticFacelets = Array(12...17) + Array(21...26) + Array(27...35)
            + Array(39...44) + Array(48...53)
        for i in staticFacelets where stickers[i] != i { return false }
        return (0...8).allSatisfy { Self.face(of: stickers[$0]) == .up }
    }

    /// All 24 whole-cube orientations as algorithms, generated by BFS from identity.
    public static let allRotations: [String] = {
        var seen: Set<[Int]> = [Array(0..<54)]
        var result: [String] = [""]
        var queue: [(alg: String, cube: CubeEngine)] = [("", CubeEngine())]
        while !queue.isEmpty {
            let (alg, cube) = queue.removeFirst()
            for r in ["x", "y", "z"] {
                var next = cube
                next.apply(r)
                if !seen.contains(next.stickers) {
                    seen.insert(next.stickers)
                    let a = alg.isEmpty ? r : alg + " " + r
                    result.append(a)
                    queue.append((a, next))
                }
            }
        }
        return result
    }()

    /// Derives the recognition state an OLL/PLL algorithm solves: the literal inverse
    /// from solved, un-rotated into the frame where the first two layers are home.
    /// Returns nil when no orientation yields a home F2L (alg is not a last-layer alg).
    public static func recognitionState(alg: String) -> CubeEngine? {
        let scrambled = applyingInverse(alg)
        if scrambled.f2lPiecesHome { return scrambled }
        for rot in allRotations.dropFirst() {
            let candidate = applying(rot, to: scrambled)
            if candidate.f2lPiecesHome { return candidate }
        }
        return nil
    }

    /// The face color showing at each of the 54 facelets. Color-level comparison is
    /// encoding-independent, so pattern-built states can be compared with move-derived states.
    public var colorScheme: [CubeEngine.Face] {
        stickers.map { Self.face(of: $0) }
    }

    /// 9 bools: which U-face stickers show the U color (yellow), positions U0...U8.
    public var uFaceYellow: [Bool] {
        (0...8).map { Self.face(of: stickers[$0]) == .up }
    }

    /// Side top-row yellows in a fixed order: F(18,19,20), R(9,10,11), B(45,46,47), L(36,37,38).
    public var sideTopYellow: [Bool] {
        [18, 19, 20, 9, 10, 11, 45, 46, 47, 36, 37, 38].map { Self.face(of: stickers[$0]) == .up }
    }

    /// Orientation signature of U-layer corners: for each of UFR, UFL, ULB, UBR,
    /// which of its 3 facelets shows the U color — nil if the piece there has no U/D sticker.
    public func uCornerOrientation() -> [Int?] {
        Self.cornerPositionOrder.prefix(4).map { name in
            guard let facelets = Self.cornerPositions[name] else { return nil }
            for (i, f) in facelets.enumerated() where Self.face(of: stickers[f]) == .up { return i }
            return nil
        }
    }

    // MARK: - Pattern construction (for StickerDatabase cross-checks)

    /// Face color convention shared with StickerDatabase: F=red, R=green, B=orange, L=blue, U=yellow.
    public enum PatternColor { case red, green, blue, orange, yellow, dark }

    /// Builds a cube state from a StickerDatabase-style pattern:
    /// uFace (9 bools, yellow or dark) and the 4 side top rows (3 colors each, F R B L order).
    /// The first two layers are left solved; side top rows get the pattern colors.
    public static func stateFromPattern(uFace: [Bool],
                                        frontTop: [PatternColor],
                                        rightTop: [PatternColor],
                                        backTop: [PatternColor],
                                        leftTop: [PatternColor]) -> CubeEngine {
        var cube = CubeEngine()
        let colorFace: (PatternColor) -> Face? = { c in
            switch c {
            case .red: return .front
            case .green: return .right
            case .blue: return .left
            case .orange: return .back
            case .yellow: return .up
            case .dark: return nil
            }
        }
        let uStickers = (0...8).map { uFace[$0] ? Face.up : Face.down } // dark rendered as D-color (white)
        for i in 0...8 { cube.stickers[i] = Int(uStickers[i].rawValue) * 9 + 4 }
        let rows: [(Face, [PatternColor], [Int])] = [
            (.front, frontTop, [18, 19, 20]),
            (.right, rightTop, [9, 10, 11]),
            (.back, backTop, [45, 46, 47]),
            (.left, leftTop, [36, 37, 38])
        ]
        for (_, row, facelets) in rows {
            for (i, f) in facelets.enumerated() {
                if let face = colorFace(row[i]) {
                    cube.stickers[f] = Int(face.rawValue) * 9 + 4
                }
            }
        }
        return cube
    }
}
