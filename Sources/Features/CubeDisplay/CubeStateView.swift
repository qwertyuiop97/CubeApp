import SwiftUI

/// CubeStateView: Proper last-layer 2D sticker visualizer for OLL/PLL.
/// Lives in Features/CubeDisplay per TASKS.md Phase 3.
/// Supports 3 visual modes and scales with sizeMode.
public struct CubeStateView: View {
    let currentCase: CubeCase
    let visualMode: VisualMode
    let sizeMode: SizeMode

    public init(currentCase: CubeCase, visualMode: VisualMode, sizeMode: SizeMode) {
        self.currentCase = currentCase
        self.visualMode = visualMode
        self.sizeMode = sizeMode
    }

    public var body: some View {
        if visualMode == .textOnly {
            Color.clear
        } else {
            Canvas { context, size in
                drawLastLayer(context: context, size: size)
            }
            .background(Color.black.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func drawLastLayer(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height

        let state = computeStickerState()

        // Cross layout: U centered with side strips on four edges
        // Total cross spans 5s x 5s
        let s = min(w, h) / 5.0
        let total = 5 * s
        let startX = (w - total) / 2
        let startY = (h - total) / 2

        let uOx = startX + s
        let uOy = startY + s

        // Draw U face (3x3)
        for row in 0..<3 {
            for col in 0..<3 {
                let x = uOx + CGFloat(col) * s
                let y = uOy + CGFloat(row) * s
                let rect = CGRect(x: x + 1, y: y + 1, width: s - 2, height: s - 2)
                let color = state.uFace[row * 3 + col]
                context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(color))
                context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(.black.opacity(0.6)), lineWidth: 1)
            }
        }

        // B strip (above U) — 3 wide x 1 tall
        let bY = uOy - s
        for i in 0..<3 {
            let x = uOx + CGFloat(i) * s
            let rect = CGRect(x: x + 1, y: bY + 1, width: s - 2, height: s - 2)
            context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(state.backTop[i]))
            context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(.black.opacity(0.6)), lineWidth: 1)
        }

        // F strip (below U)
        let fY = uOy + 3 * s
        for i in 0..<3 {
            let x = uOx + CGFloat(i) * s
            let rect = CGRect(x: x + 1, y: fY + 1, width: s - 2, height: s - 2)
            context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(state.frontTop[i]))
            context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(.black.opacity(0.6)), lineWidth: 1)
        }

        // L strip (left of U) — arranged vertically (3 tall x 1 wide), index 0 at top
        let lX = uOx - s
        for i in 0..<3 {
            let y = uOy + CGFloat(i) * s
            let rect = CGRect(x: lX + 1, y: y + 1, width: s - 2, height: s - 2)
            context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(state.leftTop[i]))
            context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(.black.opacity(0.6)), lineWidth: 1)
        }

        // R strip (right of U)
        let rX = uOx + 3 * s
        for i in 0..<3 {
            let y = uOy + CGFloat(i) * s
            let rect = CGRect(x: rX + 1, y: y + 1, width: s - 2, height: s - 2)
            context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(state.rightTop[i]))
            context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(.black.opacity(0.6)), lineWidth: 1)
        }

        // Mode label hint
        if visualMode == .setup {
            context.draw(Text("setup").font(.caption2).foregroundColor(.secondary), at: CGPoint(x: w - 30, y: 12))
        }
    }

    /// Compute a last-layer sticker configuration for the current case + mode.
    /// Prefers StickerDatabase real patterns; falls back to heuristic.
    private func computeStickerState() -> LastLayerState {
        if let pat = StickerDatabase.pattern(for: currentCase.id) {
            let yellow: Color = .yellow
            let dark: Color = Color(white: 0.25, opacity: 1)
            let uCols: [Color] = pat.uFace.map { $0 ? yellow : dark }
            return LastLayerState(
                uFace: uCols,
                frontTop: pat.frontTop,
                rightTop: pat.rightTop,
                backTop: pat.backTop,
                leftTop: pat.leftTop
            )
        }
        // fallback heuristic
        let base = LastLayerState.solvedYellowTop()
        switch visualMode {
        case .textOnly:
            return base
        case .preExecution:
            return deriveRecognitionState(from: base, using: currentCase.primaryAlgorithm, caseNumber: currentCase.caseNumber, caseType: currentCase.caseType)
        case .setup:
            let inv = invertAlgorithm(currentCase.primaryAlgorithm)
            return applyAlgorithm(inv, to: base)
        }
    }

    private func deriveRecognitionState(from solved: LastLayerState, using alg: String, caseNumber: Int, caseType: String) -> LastLayerState {
        // Start from solved, apply a lightweight "case signature" based on alg tokens and case number.
        // This produces visually distinct OLL vs PLL patterns without storing per-case sticker tables.
        var st = solved
        let tokens = alg.split(separator: " ").map(String.init)

        // Simple heuristic: count U/F/R moves to decide which pieces to "mis-orient"
        var twist = 0
        var flip = 0
        for t in tokens {
            if t.contains("U") { twist = (twist + 1) % 4 }
            if t.contains("F") || t.contains("R") { flip = (flip + 1) % 3 }
        }
        let seed = (caseNumber + twist + flip) % 8

        if caseType == "OLL" {
            // OLL: mis-orient some U stickers (non-yellow on top)
            let badColor: Color = [.red, .blue, .green, .orange][seed % 4]
            // Twist 2-3 U corners or flip 2 edges
            st.uFace[0] = badColor
            st.uFace[2] = badColor
            if seed % 2 == 0 { st.uFace[6] = badColor }
            // Side hints show the "oriented" sides for the case
            st.frontTop = [.yellow, .yellow, .yellow]
            st.rightTop = [badColor, .yellow, badColor]
        } else {
            // PLL: all yellow on top, permute corners/edges
            // Cycle some side stickers
            let c = seed % 4
            st.uFace = Array(repeating: .yellow, count: 9)
            // Permute side tops to show cycle
            let order = [st.frontTop, st.rightTop, st.backTop, st.leftTop]
            st.frontTop = order[(c + 0) % 4]
            st.rightTop = order[(c + 1) % 4]
            st.backTop = order[(c + 2) % 4]
            st.leftTop = order[(c + 3) % 4]
        }
        return st
    }

    private func applyAlgorithm(_ alg: String, to start: LastLayerState) -> LastLayerState {
        var st = start
        let tokens = alg.split(separator: " ").map(String.init)
        for token in tokens {
            st = applyMove(token, to: st)
        }
        return st
    }

    private func invertAlgorithm(_ alg: String) -> String {
        // Basic inversion for WCA notation (handles ' and 2)
        let tokens = alg.split(separator: " ").map(String.init)
        let inverted = tokens.reversed().map { invertMove($0) }
        return inverted.joined(separator: " ")
    }

    private func invertMove(_ move: String) -> String {
        if move.hasSuffix("2") { return move }
        if move.hasSuffix("'") { return String(move.dropLast()) }
        return move + "'"
    }

    private func applyMove(_ move: String, to state: LastLayerState) -> LastLayerState {
        var st = state
        let m = move.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "2", with: "")
        let twice = move.hasSuffix("2")
        let prime = move.hasSuffix("'")
        let count = twice ? 2 : (prime ? 3 : 1)

        for _ in 0..<count {
            switch m {
            case "U":
                st = rotateU(st)
            case "R":
                st = rotateR(st)
            case "L":
                st = rotateL(st)
            case "F":
                st = rotateF(st)
            case "B":
                st = rotateB(st)
            default:
                break
            }
        }
        return st
    }

    // Minimal last layer move appliers (U face + adjacent top sides)
    private func rotateU(_ st: LastLayerState) -> LastLayerState {
        var s = st
        // Rotate U face clockwise
        let u = s.uFace
        s.uFace = [u[6], u[3], u[0], u[7], u[4], u[1], u[8], u[5], u[2]]
        // Cycle side tops: F -> L -> B -> R -> F ? Wait, for top view clockwise: F->R->B->L->F
        let f = s.frontTop
        let r = s.rightTop
        let b = s.backTop
        let l = s.leftTop
        s.frontTop = l
        s.rightTop = f
        s.backTop = r
        s.leftTop = b
        return s
    }

    private func rotateR(_ st: LastLayerState) -> LastLayerState {
        var s = st
        // R move affects right column of U and right side top
        let u = s.uFace
        // U right column cycles with F right, B left (inverted), etc. Simplified for visual:
        s.uFace[2] = s.frontTop[2]
        s.frontTop[2] = s.backTop[0]   // rough visual cycle for last layer belt
        s.backTop[0] = u[8]
        s.uFace[8] = u[2]

        // Twist right top side
        let rt = s.rightTop
        s.rightTop = [rt[2], rt[1], rt[0]] // simple flip for visual
        return s
    }

    private func rotateL(_ st: LastLayerState) -> LastLayerState {
        var s = st
        let u = s.uFace
        s.uFace[0] = s.backTop[2]
        s.backTop[2] = s.frontTop[0]
        s.frontTop[0] = u[6]
        s.uFace[6] = u[0]

        let lt = s.leftTop
        s.leftTop = [lt[2], lt[1], lt[0]]
        return s
    }

    private func rotateF(_ st: LastLayerState) -> LastLayerState {
        var s = st
        let u = s.uFace
        // Front affects bottom row of U
        s.uFace[6] = s.leftTop[2]
        s.leftTop[2] = s.backTop[2]
        s.backTop[2] = s.rightTop[0]
        s.rightTop[0] = u[8]  // approx
        s.uFace[8] = u[6]

        let ft = s.frontTop
        s.frontTop = [ft[2], ft[1], ft[0]]
        return s
    }

    private func rotateB(_ st: LastLayerState) -> LastLayerState {
        var s = st
        let u = s.uFace
        s.uFace[0] = s.rightTop[2]
        s.rightTop[2] = s.backTop[0]
        s.backTop[0] = s.leftTop[0]
        s.leftTop[0] = u[2]
        s.uFace[2] = u[0]

        let bt = s.backTop
        s.backTop = [bt[2], bt[1], bt[0]]
        return s
    }
}

/// Internal model for last layer stickers used by the visualizer.
private struct LastLayerState {
    var uFace: [Color]      // 9 stickers, 0 1 2 / 3 4 5 / 6 7 8
    var frontTop: [Color]   // 3
    var rightTop: [Color]
    var backTop: [Color]
    var leftTop: [Color]

    static func solvedYellowTop() -> LastLayerState {
        let y: Color = .yellow
        let r: Color = .red
        let o: Color = .orange
        let b: Color = .blue
        let g: Color = .green
        return LastLayerState(
            uFace: Array(repeating: y, count: 9),
            frontTop: [r, r, r],
            rightTop: [g, g, g],
            backTop: [o, o, o],
            leftTop: [b, b, b]
        )
    }
}
