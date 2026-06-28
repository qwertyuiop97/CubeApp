import AppKit

public enum ScreenshotService {
    /// Captures the main app window content (our floating overlay) and returns NSImage.
    /// Falls back to the full screen if window capture is unavailable.
    public static func captureOverlay() -> NSImage? {
        guard let window = NSApp.windows.first(where: { $0 is FloatingOverlayWindow }) ?? NSApp.windows.first else {
            return captureFullScreen()
        }

        let cgImage = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            CGWindowID(window.windowNumber),
            [.boundsIgnoreFraming]
        )

        if let cg = cgImage {
            return NSImage(cgImage: cg, size: window.frame.size)
        }
        return captureFullScreen()
    }

    private static func captureFullScreen() -> NSImage? {
        guard let screen = NSScreen.main else { return nil }
        let rect = screen.frame
        if let cg = CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.boundsIgnoreFraming]
        ) {
            return NSImage(cgImage: cg, size: rect.size)
        }
        return nil
    }

    /// Saves the image to Desktop with a timestamped filename.
    @discardableResult
    public static func saveToDesktop(_ image: NSImage) -> URL? {
        guard let data = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: data),
              let png = rep.representation(using: .png, properties: [:]) else { return nil }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd_HHmmss"
        let name = "CubeNotch_\(fmt.string(from: Date())).png"
        guard let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else { return nil }
        let url = desktop.appendingPathComponent(name)
        try? png.write(to: url)
        return url
    }

    /// Copies image to clipboard.
    public static func copyToClipboard(_ image: NSImage) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])
    }
}
