// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PortPeek",
    platforms: [.macOS(.v15)],
    targets: [
        .target(name: "PortPeekCore", path: "Sources/PortPeekCore"),
        .executableTarget(
            name: "PortPeek",
            dependencies: ["PortPeekCore"],
            path: "Sources/PortPeek"
        ),
        .testTarget(
            name: "PortPeekTests",
            dependencies: ["PortPeekCore"],
            path: "Tests/PortPeekTests"
        )
    ]
)
