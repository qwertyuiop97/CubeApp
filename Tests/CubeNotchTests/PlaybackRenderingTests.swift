import AppKit
import SwiftUI
import XCTest
@testable import CubeNotch

final class PlaybackRenderingTests: XCTestCase {
    func testPlaybackDetailRendersCompactAndLargeInLightAndDark() throws {
        try MainActor.assumeIsolated {
            let cubeCase = AlgorithmDatabase.pllCases[15]

            struct Host: View {
                let cubeCase: CubeCase
                let sizeMode: SizeMode
                @State private var copied = false
                @State private var alt: Int?
                var body: some View {
                    HUDCaseDetailView(
                        cubeCase: cubeCase,
                        visualMode: .preExecution,
                        sizeMode: sizeMode,
                        showCopiedFeedback: $copied,
                        copiedAltIndex: $alt,
                        scrolls: false
                    )
                }
            }

            let captures: [(String, SizeMode, CGFloat, ColorScheme)] = [
                ("compact-light", .compact, 240, .light),
                ("compact-dark", .compact, 240, .dark),
                ("large-light", .large, 440, .light),
            ]

            for (name, sizeMode, width, scheme) in captures {
                let background = scheme == .dark ? Color.black : Color.white
                let view = Host(cubeCase: cubeCase, sizeMode: sizeMode)
                    .frame(width: width)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(background)
                    .environment(\.colorScheme, scheme)
                try writeRenderedPNG(view: view, name: "playback-\(name)", minWidth: Int(width))
            }
        }
    }

    func testInvalidAlgorithmRenderHidesDiagramAndShowsError() throws {
        try MainActor.assumeIsolated {
            let cubeCase = AlgorithmDatabase.ollCases[0]
            let playback = AlgorithmPlaybackView(
                cubeCase: cubeCase,
                algorithm: "R U Q",
                visualMode: .preExecution,
                sizeMode: .compact
            )
            .frame(width: 260)
            .fixedSize(horizontal: false, vertical: true)
            .padding(8)
            .background(Color.white)
            .environment(\.colorScheme, .light)
            try writeRenderedPNG(view: playback, name: "playback-error-compact-light", minWidth: 260, maxHeight: 280)

            let invalidCase = CubeCase(
                caseNumber: 99,
                caseType: "OLL",
                name: "Invalid",
                primaryAlgorithm: "R U Q",
                alternativeAlgorithms: ["R U R' U'", "F R U R' U' F'"],
                diagramImagePlaceholder: ""
            )
            struct Host: View {
                let cubeCase: CubeCase
                @State private var copied = false
                @State private var alt: Int?
                var body: some View {
                    HUDCaseDetailView(
                        cubeCase: cubeCase,
                        visualMode: .preExecution,
                        sizeMode: .compact,
                        showCopiedFeedback: $copied,
                        copiedAltIndex: $alt,
                        scrolls: false
                    )
                }
            }
            let hud = Host(cubeCase: invalidCase)
                .frame(width: 260)
                .fixedSize(horizontal: false, vertical: true)
                .background(Color.white)
                .environment(\.colorScheme, .light)
            try writeRenderedPNG(view: hud, name: "playback-error-hud-compact-light", minWidth: 260)
        }
    }

    @MainActor
    private func writeRenderedPNG<V: View>(view: V, name: String, minWidth: Int, maxHeight: Int? = nil) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        let image = try XCTUnwrap(renderer.cgImage, name)
        XCTAssertGreaterThanOrEqual(image.width, minWidth)
        XCTAssertGreaterThan(image.height, 80, name)
        if let maxHeight {
            XCTAssertLessThan(image.height, maxHeight * 2, "Invalid playback must not include a cube diagram (\(name) h=\(image.height))")
        }
        let bitmap = NSBitmapImageRep(cgImage: image)
        let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        XCTAssertGreaterThan(png.count, 800, "Expected nonempty \(name)")
        if let directory = ProcessInfo.processInfo.environment["CUBEAPP_RENDER_DIR"] {
            let url = URL(fileURLWithPath: directory, isDirectory: true)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            try png.write(to: url.appendingPathComponent("\(name).png"))
        }
    }
}
