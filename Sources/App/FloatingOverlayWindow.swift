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

    private func frameForAnchor(_ anchor: Anchor, size: NSSize, on screen: NSScreen) -> NSRect {
        let visible = screen.visibleFrame
        let notchExtra = screen.safeAreaInsets.top
        let margin: CGFloat = 12
        let origin: NSPoint
        switch anchor {
        case .topLeft:
            origin = NSPoint(x: visible.minX + margin, y: visible.maxY - size.height - margin - notchExtra)
        case .topRight:
            origin = NSPoint(x: visible.maxX - size.width - margin, y: visible.maxY - size.height - margin - notchExtra)
        case .bottomLeft:
            origin = NSPoint(x: visible.minX + margin, y: visible.minY + margin)
        case .bottomRight:
            origin = NSPoint(x: visible.maxX - size.width - margin, y: visible.minY + margin)
        case .notch:
            origin = NSPoint(x: visible.midX - size.width / 2, y: visible.maxY - size.height - margin - notchExtra)
        case .bottomCenter:
            origin = NSPoint(x: visible.midX - size.width / 2, y: visible.minY + margin)
        }
        return NSRect(origin: origin, size: size)
    }

    private func sliverFrame(for anchor: Anchor, final: NSRect, on screen: NSScreen) -> NSRect {
        let sliverH: CGFloat = 3
        switch anchor {
        case .topLeft, .topRight, .notch:
            // sliver at the outer (top) edge
            return NSRect(x: final.origin.x, y: final.maxY - sliverH, width: final.width, height: sliverH)
        case .bottomLeft, .bottomRight, .bottomCenter:
            return NSRect(x: final.origin.x, y: final.origin.y, width: final.width, height: sliverH)
        }
    }

    public func positionAtAnchor(_ anchor: Anchor, size: NSSize, screen: NSScreen? = nil) {
        guard let screen = screen ?? NSScreen.main else { return }
        let frame = frameForAnchor(anchor, size: size, on: screen)
        self.setFrame(frame, display: true, animate: false)
    }

    public func resizeTo(_ size: NSSize, anchor: Anchor) {
        positionAtAnchor(anchor, size: size)
    }

    /// Spring slide-in from the anchor edge (glides out on show)
    public func animatedShowTo(anchor: Anchor, size: NSSize, screen: NSScreen? = nil) {
        guard let scr = screen ?? NSScreen.main else { return }
        let final = frameForAnchor(anchor, size: size, on: scr)
        let start = sliverFrame(for: anchor, final: final, on: scr)
        self.setFrame(start, display: false, animate: false)
        self.orderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.32
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.68, -0.55, 0.265, 1.55)
            ctx.allowsImplicitAnimation = true
            self.animator().setFrame(final, display: true)
        }
    }

    /// Spring slide back into the anchor edge then hide
    public func animatedHideTo(anchor: Anchor, size: NSSize, screen: NSScreen? = nil) {
        guard let scr = screen ?? NSScreen.main else {
            self.orderOut(nil)
            return
        }
        let final = frameForAnchor(anchor, size: size, on: scr)
        let sliver = sliverFrame(for: anchor, final: final, on: scr)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.26
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.68, -0.55, 0.265, 1.55)
            self.animator().setFrame(sliver, display: true)
        } completionHandler: {
            self.orderOut(nil)
            self.setContentSize(size)
        }
    }

    public var isWindowVisible: Bool {
        return self.isVisible
    }

    public func showWindow() {
        self.makeKeyAndOrderFront(nil)
    }

    public func hideWindow() {
        self.orderOut(nil)
    }

    public func toggleVisibility() {
        if isWindowVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
}
