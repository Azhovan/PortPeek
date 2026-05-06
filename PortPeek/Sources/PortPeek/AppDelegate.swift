import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let scanner = PortScannerService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "stethoscope", accessibilityDescription: "PortPeek")
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 420, height: 460)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PortListView(scanner: scanner))
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            scanner.scan()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
