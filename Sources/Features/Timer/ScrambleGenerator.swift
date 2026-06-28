import Foundation

/// WCA-valid style random-move 3x3 scramble generator.
/// Produces exactly 20 moves using faces U D F B L R with suffixes '', "'", "2".
/// Guarantees no two consecutive moves on the same face.
public enum ScrambleGenerator {
    private static let faces = ["U", "D", "F", "B", "L", "R"]
    private static let suffixes = ["", "'", "2"]

    public static func generate3x3() -> String {
        var moves: [String] = []
        var lastFace: String? = nil

        for _ in 0..<20 {
            var face = faces.randomElement()!
            while face == lastFace {
                face = faces.randomElement()!
            }
            let suffix = suffixes.randomElement()!
            moves.append("\(face)\(suffix)")
            lastFace = face
        }

        return moves.joined(separator: " ")
    }
}
