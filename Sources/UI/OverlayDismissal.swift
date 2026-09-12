import Foundation

/// Hiding the overlay. Every dismissal path in the UI funnels through here so the
/// window never depends on a single input: the close button, a double-click, the
/// keyboard, the menu bar item, and the global shortcut all hide it.
enum OverlayDismissal {
    /// Reduce Motion changes how the window hides, never whether it hides.
    enum Kind: Equatable {
        case animated
        case immediate
    }

    static func kind(reduceMotion: Bool) -> Kind {
        reduceMotion ? .immediate : .animated
    }

    static func request(reduceMotion: Bool) {
        let name: Notification.Name = kind(reduceMotion: reduceMotion) == .immediate
            ? .requestImmediateHide
            : .requestAnimatedHide
        NotificationCenter.default.post(name: name, object: nil)
    }
}
