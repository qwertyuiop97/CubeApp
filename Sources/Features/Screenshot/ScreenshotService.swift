import AppKit

public enum ScreenshotService {
    /// Captures an AppKit view's own bitmap. Returns nil for empty or blank results.
    public static func capture(view: NSView) -> NSImage? {
        let bounds = view.bounds
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        view.layoutSubtreeIfNeeded()

        if let image = bitmapCapture(view: view, bounds: bounds), !isBlank(image) {
            return image
        }
        if let image = layerCapture(view: view, bounds: bounds), !isBlank(image) {
            return image
        }
        return nil
    }

    private static func bitmapCapture(view: NSView, bounds: NSRect) -> NSImage? {
        guard let rep = view.bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
        view.cacheDisplay(in: bounds, to: rep)
        let image = NSImage(size: bounds.size)
        image.addRepresentation(rep)
        return image
    }

    private static func layerCapture(view: NSView, bounds: NSRect) -> NSImage? {
        guard let layer = view.layer else { return nil }
        let scale = max(view.window?.backingScaleFactor ?? 1, 1)
        let width = Int((bounds.width * scale).rounded(.up))
        let height = Int((bounds.height * scale).rounded(.up))
        guard width > 0, height > 0 else { return nil }

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.scaleBy(x: scale, y: scale)
        layer.render(in: context)
        guard let cgImage = context.makeImage() else { return nil }
        return NSImage(cgImage: cgImage, size: bounds.size)
    }

    private static func isBlank(_ image: NSImage) -> Bool {
        guard image.size.width > 0, image.size.height > 0 else { return true }
        if let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) {
            return isBlankBitmap(rep)
        }
        return true
    }

    /// Inspects alpha using `bytesPerRow` so row padding is not treated as pixels.
    static func isBlankBitmap(_ rep: NSBitmapImageRep) -> Bool {
        guard let data = rep.bitmapData else { return true }
        let width = rep.pixelsWide
        let height = rep.pixelsHigh
        let count = width * height
        let bpp = max(rep.bitsPerPixel / 8, 1)
        guard count > 0, bpp >= 4 else { return count == 0 }
        let bytesPerRow = rep.bytesPerRow
        guard bytesPerRow >= width * bpp else { return true }
        let alphaIndex = rep.bitmapFormat.contains(.alphaFirst) ? 0 : bpp - 1
        for y in 0..<height {
            let row = y * bytesPerRow
            for x in 0..<width {
                if data[row + x * bpp + alphaIndex] != 0 { return false }
            }
        }
        return true
    }

    /// Captures the floating overlay window's own content view. Never falls back to fullscreen.
    public static func captureOverlay() -> NSImage? {
        guard let window = overlayWindow(),
              let contentView = window.contentView else { return nil }
        return capture(view: contentView)
    }

    private static func overlayWindow() -> NSWindow? {
        NSApplication.shared.windows.first(where: { $0 is FloatingOverlayWindow })
    }

    /// Writes PNG data to `url`. Returns the URL only after a successful write.
    @discardableResult
    public static func save(_ image: NSImage, to url: URL) -> URL? {
        guard let png = pngData(from: image) else { return nil }
        do {
            try png.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    /// Saves the image to Desktop with a timestamped filename.
    @discardableResult
    public static func saveToDesktop(_ image: NSImage) -> URL? {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd_HHmmss"
        let name = "CubeNotch_\(fmt.string(from: Date())).png"
        guard let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else { return nil }
        return save(image, to: desktop.appendingPathComponent(name))
    }

    private static func pngData(from image: NSImage) -> Data? {
        guard let data = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: data) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    /// Copies image to clipboard.
    public static func copyToClipboard(_ image: NSImage) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])
    }
}
