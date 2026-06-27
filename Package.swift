// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CubeNotch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CubeNotch", targets: ["CubeNotch"])
    ],
    targets: [
        .executableTarget(
            name: "CubeNotch",
            path: "Sources"
        )
    ]
)
