import SwiftUI

/// CubeStateView: last-layer 2D sticker visualizer for OLL/PLL/F2L.
/// Diagrams come from real CubeEngine states (cached in StickerDatabase).
/// Optional `cubeState` draws that cube's actual colors (no OLL mask).
public struct CubeStateView: View {
    let currentCase: CubeCase
    let visualMode: VisualMode
    let sizeMode: SizeMode
    var uFaceOnly: Bool = false
    var cubeState: CubeEngine? = nil

    public init(currentCase: CubeCase, visualMode: VisualMode, sizeMode: SizeMode, uFaceOnly: Bool = false, cubeState: CubeEngine? = nil) {
        self.currentCase = currentCase
        self.visualMode = visualMode
        self.sizeMode = sizeMode
        self.uFaceOnly = uFaceOnly
        self.cubeState = cubeState
    }

    /// Cross-layout stickers the canvas will paint, or nil when the case cannot be shown.
    var displayPattern: StickerPattern? {
        if let cubeState {
            return StickerDatabase.displayPattern(from: cubeState, ollOrientationMask: false)
        }
        return StickerDatabase.pattern(for: currentCase)
    }

    var isUnavailable: Bool { displayPattern == nil }

    public var body: some View {
        if visualMode == .textOnly {
            Color.clear
        } else if let pattern = displayPattern {
            Canvas { context, size in
                drawLastLayer(context: context, size: size, pattern: pattern)
            }
            .background(Color.black.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            Text("unavailable")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityLabel("unavailable")
        }
    }

    private func drawLastLayer(context: GraphicsContext, size: CGSize, pattern: StickerPattern) {
        let w = size.width
        let h = size.height

        if uFaceOnly {
            let pad: CGFloat = 3
            let s = (min(w, h) - pad * 2) / 3.0
            let uOx = (w - 3 * s) / 2
            let uOy = (h - 3 * s) / 2
            for row in 0..<3 {
                for col in 0..<3 {
                    let x = uOx + CGFloat(col) * s
                    let y = uOy + CGFloat(row) * s
                    let rect = CGRect(x: x + 1.5, y: y + 1.5, width: s - 3, height: s - 3)
                    let color = swiftColor(pattern.uFace[row * 3 + col])
                    context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(color))
                    context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(.black.opacity(0.5)), lineWidth: 1)
                }
            }
            return
        }

        let s = min(w, h) / 5.0
        let total = 5 * s
        let startX = (w - total) / 2
        let startY = (h - total) / 2

        let uOx = startX + s
        let uOy = startY + s

        for row in 0..<3 {
            for col in 0..<3 {
                let x = uOx + CGFloat(col) * s
                let y = uOy + CGFloat(row) * s
                let rect = CGRect(x: x + 1, y: y + 1, width: s - 1, height: s - 1)
                let color = swiftColor(pattern.uFace[row * 3 + col])
                context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(color))
                context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(.black.opacity(0.6)), lineWidth: 1)
            }
        }

        let bY = uOy - s
        for i in 0..<3 {
            let x = uOx + CGFloat(i) * s
            let rect = CGRect(x: x + 1, y: bY + 1, width: s - 1, height: s - 1)
            context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(swiftColor(pattern.backTop[i])))
            context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(.black.opacity(0.6)), lineWidth: 1)
        }

        let fY = uOy + 3 * s
        for i in 0..<3 {
            let x = uOx + CGFloat(i) * s
            let rect = CGRect(x: x + 1, y: fY + 1, width: s - 1, height: s - 1)
            context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(swiftColor(pattern.frontTop[i])))
            context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(.black.opacity(0.6)), lineWidth: 1)
        }

        let lX = uOx - s
        for i in 0..<3 {
            let y = uOy + CGFloat(i) * s
            let rect = CGRect(x: lX + 1, y: y + 1, width: s - 1, height: s - 1)
            context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(swiftColor(pattern.leftTop[i])))
            context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(.black.opacity(0.6)), lineWidth: 1)
        }

        let rX = uOx + 3 * s
        for i in 0..<3 {
            let y = uOy + CGFloat(i) * s
            let rect = CGRect(x: rX + 1, y: y + 1, width: s - 1, height: s - 1)
            context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(swiftColor(pattern.rightTop[i])))
            context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(.black.opacity(0.6)), lineWidth: 1)
        }

        if visualMode == .setup {
            context.draw(Text("setup").font(.caption2).foregroundColor(.secondary), at: CGPoint(x: w - 30, y: 12))
        }
    }

    private func swiftColor(_ color: StickerColor) -> Color {
        switch color {
        case .yellow: return .yellow
        case .red: return .red
        case .green: return .green
        case .orange: return .orange
        case .blue: return .blue
        case .white: return .white
        case .dark: return Color(white: 0.25, opacity: 1)
        }
    }
}
