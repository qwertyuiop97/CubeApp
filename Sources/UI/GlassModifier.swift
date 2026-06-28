import SwiftUI

// Phase 15A-1: Liquid Glass modifier (macOS 26+)
// Provides .cubeNotchGlass() which uses the new glass APIs when available,
// falling back to ultraThinMaterial + tint for older macOS and when Reduce Transparency is on.

public struct GlassModifier<S: Shape>: ViewModifier {
    let shape: S
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            if reduceTransparency {
                content
                    .background(.regularMaterial, in: shape)
            } else {
                content
                    .glassEffect(.regular, in: shape)
            }
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
        }
    }
}

public extension View {
    func cubeNotchGlass<S: Shape>(shape: S) -> some View {
        modifier(GlassModifier(shape: shape))
    }

    // Convenience for common rounded rect
    func cubeNotchGlass(cornerRadius: CGFloat = 12) -> some View {
        cubeNotchGlass(shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
