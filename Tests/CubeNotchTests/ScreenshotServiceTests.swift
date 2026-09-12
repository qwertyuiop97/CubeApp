import AppKit
import SwiftUI
import XCTest
@testable import CubeNotch

final class ScreenshotServiceTests: XCTestCase {
    func testCaptureViewReturnsNonBlankImageMatchingViewSize() {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 32, height: 16))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.systemRed.cgColor
        view.layoutSubtreeIfNeeded()

        let image = ScreenshotService.capture(view: view)

        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 32)
        XCTAssertEqual(image?.size.height, 16)
        XCTAssertFalse(isFullyTransparent(image), "Capture must not silently return a blank image")
    }

    func testCaptureSwiftUIHostingViewReturnsNonBlankImage() {
        let hosting = NSHostingView(rootView: Color.orange.frame(width: 20, height: 10))
        hosting.frame = NSRect(x: 0, y: 0, width: 20, height: 10)
        hosting.layoutSubtreeIfNeeded()

        let image = ScreenshotService.capture(view: hosting)

        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 20)
        XCTAssertEqual(image?.size.height, 10)
        XCTAssertFalse(isFullyTransparent(image), "SwiftUI hosting capture must not be blank")
    }

    func testSaveToURLWritesPNG() throws {
        let image = try XCTUnwrap(sampleImage())
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("cube-shot-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let url = dir.appendingPathComponent("shot.png")
        XCTAssertEqual(ScreenshotService.save(image, to: url), url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let data = try Data(contentsOf: url)
        XCTAssertTrue(data.starts(with: [0x89, 0x50, 0x4E, 0x47]), "Saved file must be PNG")
    }

    func testSaveToMissingDirectoryReturnsNil() throws {
        let image = try XCTUnwrap(sampleImage())
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("cube-shot-missing-\(UUID().uuidString)")
            .appendingPathComponent("shot.png")
        XCTAssertNil(ScreenshotService.save(image, to: missing))
        XCTAssertFalse(FileManager.default.fileExists(atPath: missing.path))
    }

    func testCaptureZeroSizeViewReturnsNil() {
        let view = NSView(frame: .zero)
        XCTAssertNil(ScreenshotService.capture(view: view))
    }

    func testCaptureOverlayWithoutOwnWindowReturnsNil() {
        NSApplication.shared.windows
            .filter { $0 is FloatingOverlayWindow }
            .forEach { $0.orderOut(nil); $0.close() }
        XCTAssertNil(ScreenshotService.captureOverlay())
    }

    func testIsBlankBitmapDetectsOpaquePixelAfterRowPadding() {
        let rep = makeBitmap(
            width: 3,
            height: 2,
            bytesPerRow: 16,
            alphaFirst: false,
            paddingByte: 0,
            opaquePixel: (x: 2, y: 1)
        )
        XCTAssertFalse(
            ScreenshotService.isBlankBitmap(rep),
            "Opaque last-row pixel must be found using bytesPerRow, not packed i*bpp indexing"
        )
    }

    func testIsBlankBitmapIgnoresNonZeroRowPaddingOnTransparentImage() {
        let rep = makeBitmap(
            width: 3,
            height: 2,
            bytesPerRow: 16,
            alphaFirst: false,
            paddingByte: 255,
            opaquePixel: nil
        )
        XCTAssertTrue(
            ScreenshotService.isBlankBitmap(rep),
            "Padding bytes must not be read as alpha"
        )
    }

    func testIsBlankBitmapDetectsAlphaFirstOpaquePixelAfterRowPadding() {
        let rep = makeBitmap(
            width: 3,
            height: 2,
            bytesPerRow: 16,
            alphaFirst: true,
            paddingByte: 0,
            opaquePixel: (x: 2, y: 1)
        )
        XCTAssertFalse(
            ScreenshotService.isBlankBitmap(rep),
            "alphaFirst last-row pixel must be found with bytesPerRow"
        )
    }

    func testCaptureOverlayUsesOwnContentViewNotScreenSize() {
        let content = NSView(frame: NSRect(x: 0, y: 0, width: 24, height: 12))
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor.systemGreen.cgColor

        let window = FloatingOverlayWindow()
        window.setFrame(NSRect(x: -10_000, y: -10_000, width: 24, height: 12), display: false)
        window.contentView = content
        window.orderOut(nil)
        defer { window.close() }

        let image = ScreenshotService.captureOverlay()
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 24)
        XCTAssertEqual(image?.size.height, 12)
        XCTAssertFalse(isFullyTransparent(image))
        if let screen = NSScreen.main {
            XCTAssertNotEqual(image?.size, screen.frame.size)
        }
    }

    private func makeBitmap(
        width: Int,
        height: Int,
        bytesPerRow: Int,
        alphaFirst: Bool,
        paddingByte: UInt8,
        opaquePixel: (x: Int, y: Int)?
    ) -> NSBitmapImageRep {
        let bytesPerPixel = 4
        let packedRow = width * bytesPerPixel
        precondition(bytesPerRow > packedRow)
        var buf = [UInt8](repeating: 0, count: bytesPerRow * height)
        if paddingByte != 0 {
            for y in 0..<height {
                for p in packedRow..<bytesPerRow {
                    buf[y * bytesPerRow + p] = paddingByte
                }
            }
        }
        if let pixel = opaquePixel {
            let base = pixel.y * bytesPerRow + pixel.x * bytesPerPixel
            if alphaFirst {
                buf[base] = 255
                buf[base + 1] = 0
                buf[base + 2] = 255
                buf[base + 3] = 0
            } else {
                buf[base] = 255
                buf[base + 1] = 0
                buf[base + 2] = 0
                buf[base + 3] = 255
            }
        }
        let format: NSBitmapImageRep.Format = alphaFirst ? .alphaFirst : []
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: format,
            bytesPerRow: bytesPerRow,
            bitsPerPixel: 32
        )!
        XCTAssertEqual(rep.bytesPerRow, bytesPerRow)
        XCTAssertEqual(rep.bitmapFormat.contains(.alphaFirst), alphaFirst)
        rep.bitmapData?.update(from: &buf, count: buf.count)
        return rep
    }

    private func sampleImage() -> NSImage? {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 8, height: 8))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.systemBlue.cgColor
        view.layoutSubtreeIfNeeded()
        return ScreenshotService.capture(view: view)
    }

    private func isFullyTransparent(_ image: NSImage?) -> Bool {
        guard let image else { return true }
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.bitmapData else { return true }
        let bpp = max(rep.bitsPerPixel / 8, 1)
        let count = rep.pixelsWide * rep.pixelsHigh
        guard count > 0 else { return true }
        let alphaIndex: Int
        switch rep.bitmapFormat.contains(.alphaFirst) {
        case true: alphaIndex = 0
        case false: alphaIndex = bpp - 1
        }
        guard bpp >= 4 else { return false }
        for i in 0..<count {
            if data[i * bpp + alphaIndex] != 0 { return false }
        }
        return true
    }
}
