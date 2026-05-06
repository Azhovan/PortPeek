import AppKit
import SwiftUI

@MainActor
func capture() {
    let scanner = PortScannerService()
    scanner.scanSync()

    let view = PortListView(scanner: scanner)
    let hostingView = NSHostingView(rootView: view)
    let size = NSSize(width: 420, height: 460)
    hostingView.frame = NSRect(origin: .zero, size: size)

    let window = NSWindow(
        contentRect: NSRect(origin: .zero, size: size),
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
    )
    window.contentView = hostingView
    window.orderBack(nil)

    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
    hostingView.layoutSubtreeIfNeeded()

    guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
        print("Error: could not create bitmap representation")
        exit(1)
    }
    hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)

    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("Error: could not encode PNG")
        exit(1)
    }

    let outputPath: String
    if CommandLine.arguments.count > 1 {
        outputPath = CommandLine.arguments[1]
    } else {
        outputPath = "port-peek.png"
    }

    let url = URL(fileURLWithPath: outputPath)
    do {
        try pngData.write(to: url)
        print("Screenshot saved to \(url.path)")
    } catch {
        print("Error writing file: \(error.localizedDescription)")
        exit(1)
    }

    exit(0)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
capture()
