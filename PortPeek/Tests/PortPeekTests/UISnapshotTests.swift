import XCTest
import SwiftUI
import AppKit
@testable import PortPeekCore

final class UISnapshotTests: XCTestCase {

    @MainActor
    func testPortListViewWithEntries() {
        let scanner = PortScannerService()
        scanner.entries = [
            PortEntry(port: 3000, processName: "node", pid: 12421),
            PortEntry(port: 5173, processName: "vite", pid: 44219),
            PortEntry(port: 8080, processName: "go-server", pid: 88731),
        ]
        scanner.isScanning = false

        let view = PortListView(scanner: scanner)
        SnapshotTestHelper.assertSnapshot(view, named: "port_list_with_entries")
    }

    @MainActor
    func testPortListViewEmpty() {
        let scanner = PortScannerService()
        scanner.entries = []
        scanner.isScanning = false

        let view = PortListView(scanner: scanner)
        SnapshotTestHelper.assertSnapshot(view, named: "port_list_empty")
    }

    @MainActor
    func testPortListViewSingleEntry() {
        let scanner = PortScannerService()
        scanner.entries = [
            PortEntry(port: 3000, processName: "node", pid: 12421),
        ]
        scanner.isScanning = false

        let view = PortListView(scanner: scanner)
        SnapshotTestHelper.assertSnapshot(view, named: "port_list_single_entry")
    }

    @MainActor
    func testPortListViewManyEntries() {
        let scanner = PortScannerService()
        scanner.entries = (1...10).map { i in
            PortEntry(port: 3000 + i * 100, processName: "service-\(i)", pid: Int32(10000 + i))
        }
        scanner.isScanning = false

        let view = PortListView(scanner: scanner)
        SnapshotTestHelper.assertSnapshot(view, named: "port_list_many_entries")
    }

    @MainActor
    func testPortListViewWithError() {
        let scanner = PortScannerService()
        scanner.entries = []
        scanner.isScanning = false
        scanner.lastError = "Failed to execute lsof"

        let view = PortListView(scanner: scanner)
        SnapshotTestHelper.assertSnapshot(view, named: "port_list_with_error")
    }

    @MainActor
    func testPortRowViewStandard() {
        let entry = PortEntry(port: 3000, processName: "node", pid: 12421)
        let view = PortRowView(entry: entry) {}
            .padding(12)
            .frame(width: 420)

        SnapshotTestHelper.assertSnapshot(view, size: NSSize(width: 420, height: 50), named: "port_row_standard")
    }

    @MainActor
    func testPortRowViewLongProcessName() {
        let entry = PortEntry(port: 8080, processName: "com.docker.backend.proxy", pid: 3923)
        let view = PortRowView(entry: entry) {}
            .padding(12)
            .frame(width: 420)

        SnapshotTestHelper.assertSnapshot(view, size: NSSize(width: 420, height: 50), named: "port_row_long_name")
    }

    @MainActor
    func testPortRowViewHighPort() {
        let entry = PortEntry(port: 65535, processName: "test", pid: 99999)
        let view = PortRowView(entry: entry) {}
            .padding(12)
            .frame(width: 420)

        SnapshotTestHelper.assertSnapshot(view, size: NSSize(width: 420, height: 50), named: "port_row_high_port")
    }

    // MARK: - Element verification tests

    @MainActor
    func testViewRendersAtCorrectSize() {
        let scanner = PortScannerService()
        scanner.entries = []
        scanner.isScanning = false

        let bitmap = SnapshotTestHelper.renderView(
            PortListView(scanner: scanner),
            size: NSSize(width: 420, height: 460)
        )
        XCTAssertNotNil(bitmap, "View should render successfully")
        XCTAssertEqual(bitmap?.pixelsWide, 420)
        XCTAssertEqual(bitmap?.pixelsHigh, 460)
    }

    @MainActor
    func testRenderedImageHasContent() {
        let scanner = PortScannerService()
        scanner.entries = [
            PortEntry(port: 3000, processName: "node", pid: 12421),
        ]
        scanner.isScanning = false

        guard let bitmap = SnapshotTestHelper.renderView(
            PortListView(scanner: scanner),
            size: NSSize(width: 420, height: 460)
        ) else {
            XCTFail("Failed to render")
            return
        }

        guard let data = SnapshotTestHelper.pngData(from: bitmap) else {
            XCTFail("Failed to encode PNG")
            return
        }

        XCTAssertGreaterThan(data.count, 3000, "Rendered image should have visible content (not blank)")
    }

    @MainActor
    func testEmptyStateIsVisuallyDistinctFromPopulated() {
        let emptyScanner = PortScannerService()
        emptyScanner.entries = []
        emptyScanner.isScanning = false

        let populatedScanner = PortScannerService()
        populatedScanner.entries = [
            PortEntry(port: 3000, processName: "node", pid: 12421),
        ]
        populatedScanner.isScanning = false

        let size = NSSize(width: 420, height: 460)

        guard let emptyBitmap = SnapshotTestHelper.renderView(PortListView(scanner: emptyScanner), size: size),
              let populatedBitmap = SnapshotTestHelper.renderView(PortListView(scanner: populatedScanner), size: size),
              let emptyPNG = SnapshotTestHelper.pngData(from: emptyBitmap),
              let populatedPNG = SnapshotTestHelper.pngData(from: populatedBitmap) else {
            XCTFail("Failed to render views")
            return
        }

        XCTAssertNotEqual(emptyPNG, populatedPNG, "Empty and populated states should render differently")
    }

    @MainActor
    func testErrorStateRendersWithoutCrash() {
        let scanner = PortScannerService()
        scanner.entries = []
        scanner.isScanning = false
        scanner.lastError = "Connection failed"

        let bitmap = SnapshotTestHelper.renderView(
            PortListView(scanner: scanner),
            size: NSSize(width: 420, height: 460)
        )
        XCTAssertNotNil(bitmap, "Error state should render without crashing")

        guard let data = SnapshotTestHelper.pngData(from: bitmap!) else {
            XCTFail("Failed to encode error state")
            return
        }
        XCTAssertGreaterThan(data.count, 1000, "Error state should produce a non-trivial image")
    }

    @MainActor
    func testDifferentPortCountsProduceDifferentImages() {
        let size = NSSize(width: 420, height: 460)

        let scanner1 = PortScannerService()
        scanner1.entries = [PortEntry(port: 3000, processName: "a", pid: 1)]
        scanner1.isScanning = false

        let scanner3 = PortScannerService()
        scanner3.entries = [
            PortEntry(port: 3000, processName: "a", pid: 1),
            PortEntry(port: 4000, processName: "b", pid: 2),
            PortEntry(port: 5000, processName: "c", pid: 3),
        ]
        scanner3.isScanning = false

        guard let bm1 = SnapshotTestHelper.renderView(PortListView(scanner: scanner1), size: size),
              let bm3 = SnapshotTestHelper.renderView(PortListView(scanner: scanner3), size: size),
              let png1 = SnapshotTestHelper.pngData(from: bm1),
              let png3 = SnapshotTestHelper.pngData(from: bm3) else {
            XCTFail("Failed to render")
            return
        }

        XCTAssertNotEqual(png1, png3, "Different entry counts should produce different renders")
    }
}
