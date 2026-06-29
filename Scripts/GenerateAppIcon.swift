#!/usr/bin/swift
// Scripts/GenerateAppIcon.swift
// Renders SF Symbol "cube.fill" into all required macOS app icon sizes.
// Run with: swift Scripts/GenerateAppIcon.swift
// Requires macOS (AppKit).

import AppKit
import Foundation

let iconsetDir = "Resources/Assets.xcassets/AppIcon.appiconset"

let sizes: [(name: String, size: CGFloat, scale: Int)] = [
    ("icon_16x16", 16, 1),
    ("icon_16x16@2x", 16, 2),
    ("icon_32x32", 32, 1),
    ("icon_32x32@2x", 32, 2),
    ("icon_128x128", 128, 1),
    ("icon_128x128@2x", 128, 2),
    ("icon_256x256", 256, 1),
    ("icon_256x256@2x", 256, 2),
    ("icon_512x512", 512, 1),
    ("icon_512x512@2x", 512, 2),
]

func renderCube(size: CGFloat, scale: Int) -> NSImage {
    let pixelSize = size * CGFloat(scale)
    let image = NSImage(size: NSSize(width: pixelSize, height: pixelSize))
    image.lockFocus()

    // Dark background per spec
    NSColor(calibratedRed: 0.102, green: 0.102, blue: 0.102, alpha: 1.0).setFill()
    NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize).fill()

    // Draw SF Symbol "cube.fill" centered with subtle blue accent
    if let symbol = NSImage(systemSymbolName: "cube.fill", accessibilityDescription: nil) {
        let config = NSImage.SymbolConfiguration(pointSize: pixelSize * 0.58, weight: .medium)
        if let configured = symbol.withSymbolConfiguration(config) {
            let accent = NSColor(calibratedRed: 0.20, green: 0.55, blue: 0.95, alpha: 1.0)

            // Tint by drawing the template image with the accent color as fill
            configured.isTemplate = true
            let iconSize = configured.size
            let x = (pixelSize - iconSize.width) / 2
            let y = (pixelSize - iconSize.height) / 2
            accent.set()
            configured.draw(in: NSRect(x: x, y: y, width: iconSize.width, height: iconSize.height))
        }
    }

    image.unlockFocus()
    return image
}

func savePNG(image: NSImage, to url: URL) {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to encode PNG for \(url.lastPathComponent)")
        return
    }
    do {
        try pngData.write(to: url)
        print("Wrote \(url.lastPathComponent)")
    } catch {
        print("Write failed for \(url.lastPathComponent): \(error)")
    }
}

func main() {
    let fm = FileManager.default
    if !fm.fileExists(atPath: iconsetDir) {
        try? fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)
    }

    for (baseName, pt, scale) in sizes {
        let img = renderCube(size: pt, scale: scale)
        let filename = "\(baseName).png"
        let url = URL(fileURLWithPath: "\(iconsetDir)/\(filename)")
        savePNG(image: img, to: url)
    }

    print("App icon generation complete.")
}

main()
