import AppKit
import SwiftUI
import XCTest

@MainActor
enum SnapshotTestHelper {
    static let snapshotsDirectory: URL = {
        let testFile = URL(fileURLWithPath: #filePath)
        return testFile.deletingLastPathComponent().appendingPathComponent("Snapshots")
    }()

    static func renderView<V: View>(_ view: V, size: NSSize) -> NSBitmapImageRep? {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(origin: .zero, size: size)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.orderBack(nil)

        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.3))
        hostingView.layoutSubtreeIfNeeded()

        guard let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            return nil
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)

        window.orderOut(nil)
        return bitmap
    }

    static func pngData(from bitmap: NSBitmapImageRep) -> Data? {
        bitmap.representation(using: .png, properties: [:])
    }

    static func saveReference(_ data: Data, name: String) throws {
        let url = snapshotsDirectory.appendingPathComponent("\(name).png")
        try FileManager.default.createDirectory(at: snapshotsDirectory, withIntermediateDirectories: true)
        try data.write(to: url)
    }

    static func loadReference(name: String) -> Data? {
        let url = snapshotsDirectory.appendingPathComponent("\(name).png")
        return try? Data(contentsOf: url)
    }

    static func assertSnapshot<V: View>(
        _ view: V,
        size: NSSize = NSSize(width: 420, height: 460),
        named name: String,
        record: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let bitmap = renderView(view, size: size) else {
            XCTFail("Failed to render view", file: file, line: line)
            return
        }

        guard let currentPNG = pngData(from: bitmap) else {
            XCTFail("Failed to encode PNG", file: file, line: line)
            return
        }

        if record {
            do {
                try saveReference(currentPNG, name: name)
                XCTFail("Recording snapshot '\(name)'. Remove record flag to run assertion.", file: file, line: line)
            } catch {
                XCTFail("Failed to save reference: \(error)", file: file, line: line)
            }
            return
        }

        guard let referencePNG = loadReference(name: name) else {
            do {
                try saveReference(currentPNG, name: name)
                XCTFail(
                    "No reference snapshot '\(name)' found. Created new reference. Re-run to verify.",
                    file: file, line: line
                )
            } catch {
                XCTFail("No reference and failed to save: \(error)", file: file, line: line)
            }
            return
        }

        if currentPNG != referencePNG {
            let failurePath = snapshotsDirectory
                .appendingPathComponent("\(name)_FAILURE.png")
            try? currentPNG.write(to: failurePath)
            XCTFail(
                "Snapshot '\(name)' does not match reference. Failure image saved to \(failurePath.path)",
                file: file, line: line
            )
        }
    }
}
