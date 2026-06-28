import AppKit
import SwiftUI

final class LibraryWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.minSize = NSSize(width: 900, height: 600)
        window.title = "CubeNotch Library"
        window.center()
        self.init(window: window)

        let libraryView = LibraryView()
        let hostingController = NSHostingController(rootView: libraryView)
        window.contentViewController = hostingController
    }
}
