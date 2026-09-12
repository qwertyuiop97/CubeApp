import AppKit
import SwiftUI
import XCTest
@testable import CubeNotch

final class DiagramRenderingTests: XCTestCase {
    func testDiagramsRenderAtEverySizeInLightAndDarkMode() throws {
        try MainActor.assumeIsolated {
            let cases = [AlgorithmDatabase.ollCases[0], AlgorithmDatabase.ollCases[26], AlgorithmDatabase.pllCases[15], F2LDatabase.f2lCases[0]]
            for size in SizeMode.allCases {
                let side: CGFloat = size == .compact ? 96 : (size == .medium ? 144 : 192)
                for scheme in [ColorScheme.light, .dark] {
                    let view = HStack(spacing: 16) {
                        ForEach(cases) { cubeCase in
                            VStack(spacing: 8) {
                                Text(cubeCase.id).font(.caption)
                                CubeStateView(currentCase: cubeCase, visualMode: .preExecution, sizeMode: size)
                                    .frame(width: side, height: side)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .environment(\.colorScheme, scheme)
                    let renderer = ImageRenderer(content: view)
                    renderer.scale = 2
                    let image = try XCTUnwrap(renderer.cgImage, "\(size.rawValue), scheme=\(scheme)")
                    XCTAssertGreaterThan(image.width, 0)
                    XCTAssertGreaterThan(image.height, Int(side))
                    let bitmap = NSBitmapImageRep(cgImage: image)
                    let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
                    XCTAssertGreaterThan(png.count, 1000, "Expected nonempty rendered diagrams")
                    if let directory = ProcessInfo.processInfo.environment["CUBEAPP_RENDER_DIR"] {
                        let url = URL(fileURLWithPath: directory, isDirectory: true)
                        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                        try png.write(to: url.appendingPathComponent("diagrams-\(size.rawValue)-\(scheme).png"))
                    }
                }
            }
        }
    }
}
