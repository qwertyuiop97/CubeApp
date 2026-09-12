import Foundation

/// Last-layer (and F2L inverse) sticker colors in **cross-layout display order**.
/// U is row-major as seen looking at U. Side strips: F/B left-to-right, L/R top-to-bottom.
/// B and R are reversed from CubeEngine's front-on face arrays.
struct StickerPattern: Equatable {
    var uFace: [StickerColor]
    var frontTop: [StickerColor]
    var rightTop: [StickerColor]
    var backTop: [StickerColor]
    var leftTop: [StickerColor]
}

enum StickerColor: Equatable {
    case yellow, red, green, orange, blue, white, dark
}

enum StickerDatabase {
    private static let casesByID: [String: CubeCase] = {
        var map: [String: CubeCase] = [:]
        for c in AlgorithmDatabase.ollCases + AlgorithmDatabase.pllCases + F2LDatabase.f2lCases {
            map[c.id] = c
        }
        return map
    }()

    private static let cache: [String: StickerPattern] = {
        var map: [String: StickerPattern] = [:]
        for c in casesByID.values {
            if let pattern = derive(c) {
                map[c.id] = pattern
            }
        }
        return map
    }()

    static func pattern(for caseID: String) -> StickerPattern? {
        if let cached = cache[caseID] { return cached }
        guard let cubeCase = casesByID[caseID] else { return nil }
        return derive(cubeCase)
    }

    static func pattern(for cubeCase: CubeCase) -> StickerPattern? {
        if let cached = cache[cubeCase.id], casesByID[cubeCase.id] == cubeCase {
            return cached
        }
        return derive(cubeCase)
    }

    /// Display-ordered stickers from a real cube. `ollOrientationMask` paints non-U
    /// colors as dark so OLL diagrams keep yellow orientation clues only.
    static func displayPattern(from cube: CubeEngine, ollOrientationMask: Bool) -> StickerPattern {
        func mapped(_ index: Int) -> StickerColor {
            let color = color(for: cube.colorScheme[index])
            if ollOrientationMask {
                return color == .yellow ? .yellow : .dark
            }
            return color
        }
        func side(_ indices: [Int], reverse: Bool) -> [StickerColor] {
            let colors = indices.map(mapped)
            return reverse ? Array(colors.reversed()) : colors
        }
        return StickerPattern(
            uFace: (0...8).map(mapped),
            frontTop: side([18, 19, 20], reverse: false),
            rightTop: side([9, 10, 11], reverse: true),
            backTop: side([45, 46, 47], reverse: true),
            leftTop: side([36, 37, 38], reverse: false)
        )
    }

    static func color(for face: CubeEngine.Face) -> StickerColor {
        switch face {
        case .up: return .yellow
        case .right: return .green
        case .front: return .red
        case .down: return .white
        case .left: return .blue
        case .back: return .orange
        }
    }

    /// Engine-order side-top yellows (F R B L) reconstructed from a display pattern.
    static func engineSideTopYellow(from pattern: StickerPattern) -> [Bool] {
        let f = pattern.frontTop.map { $0 == .yellow }
        let r = Array(pattern.rightTop.reversed()).map { $0 == .yellow }
        let b = Array(pattern.backTop.reversed()).map { $0 == .yellow }
        let l = pattern.leftTop.map { $0 == .yellow }
        return f + r + b + l
    }

    private static func derive(_ cubeCase: CubeCase) -> StickerPattern? {
        let alg = cubeCase.primaryAlgorithm
        guard (try? CubeEngine.parse(alg)) != nil else { return nil }

        switch cubeCase.caseType {
        case "F2L":
            let state = CubeEngine.applyingNormalizedInverse(alg)
            return displayPattern(from: state, ollOrientationMask: false)
        case "OLL":
            guard let state = lastLayerRecognitionState(alg: alg) else { return nil }
            return displayPattern(from: state, ollOrientationMask: true)
        case "PLL":
            guard let state = lastLayerRecognitionState(alg: alg) else { return nil }
            return displayPattern(from: state, ollOrientationMask: false)
        default:
            return nil
        }
    }

    /// Strict-parsed inverse in the recognition frame: prefer the engine's
    /// last-layer recognition model; fall back to normalized inverse when F2L is home.
    private static func lastLayerRecognitionState(alg: String) -> CubeEngine? {
        if let state = CubeEngine.recognitionState(alg: alg) {
            return state
        }
        let normalized = CubeEngine.applyingNormalizedInverse(alg)
        return normalized.f2lPiecesHome ? normalized : nil
    }
}
