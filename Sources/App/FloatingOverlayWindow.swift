import AppKit

public final class FloatingOverlayWindow: NSPanel {
    public init() {
        let initialSize = NSSize(width: 340, height: 440)
        let contentRect = NSRect(origin: .zero, size: initialSize)

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.ignoresMouseEvents = false
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.becomesKeyOnlyIfNeeded = true   // helps non-activating behavior

        positionAtAnchor(.topRight, size: initialSize)
    }

    public func positionAtAnchor(_ anchor: Anchor, size: NSSize) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        _ = screen.frame.height - visible.height
        let notchExtra = screen.safeAreaInsets.top
        let margin: CGFloat = 12

        let origin: NSPoint
        switch anchor {
        case .topLeft:
            origin = NSPoint(
                x: visible.minX + margin,
                y: visible.maxY - size.height - margin - notchExtra
            )
        case .topRight:
            origin = NSPoint(
                x: visible.maxX - size.width - margin,
                y: visible.maxY - size.height - margin - notchExtra
            )
        case .bottomLeft:
            origin = NSPoint(
                x: visible.minX + margin,
                y: visible.minY + margin
            )
        case .bottomRight:
            origin = NSPoint(
                x: visible.maxX - size.width - margin,
                y: visible.minY + margin
            )
        }

        let newFrame = NSRect(origin: origin, size: size)
        self.setFrame(newFrame, display: true, animate: true)
    }

    public func resizeTo(_ size: NSSize, anchor: Anchor) {
        positionAtAnchor(anchor, size: size)
    }
}
