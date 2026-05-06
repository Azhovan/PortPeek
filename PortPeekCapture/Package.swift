// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PortPeekCapture",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "PortPeekCapture", path: "Sources/PortPeekCapture")
    ]
)
