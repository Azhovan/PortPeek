import XCTest
@testable import PortPeekCore

final class PortScannerServiceTests: XCTestCase {

    @MainActor
    func testScanSyncPopulatesEntries() {
        let service = PortScannerService()
        service.scanSync()

        XCTAssertFalse(service.entries.isEmpty)
        XCTAssertNil(service.lastError)
        XCTAssertFalse(service.isScanning)
    }

    @MainActor
    func testScanSyncSetsIsScanningToFalse() {
        let service = PortScannerService()
        service.scanSync()
        XCTAssertFalse(service.isScanning)
    }

    @MainActor
    func testAllEntriesHaveValidPortNumbers() {
        let service = PortScannerService()
        service.scanSync()

        for entry in service.entries {
            XCTAssertGreaterThan(entry.port, 0)
            XCTAssertLessThanOrEqual(entry.port, 65535)
        }
    }

    @MainActor
    func testAllEntriesHaveNonEmptyProcessNames() {
        let service = PortScannerService()
        service.scanSync()

        for entry in service.entries {
            XCTAssertFalse(entry.processName.isEmpty)
        }
    }

    @MainActor
    func testAllEntriesHavePositivePIDs() {
        let service = PortScannerService()
        service.scanSync()

        for entry in service.entries {
            XCTAssertGreaterThan(entry.pid, 0)
        }
    }

    @MainActor
    func testEntriesSortedByPort() {
        let service = PortScannerService()
        service.scanSync()

        let ports = service.entries.map(\.port)
        XCTAssertEqual(ports, ports.sorted())
    }

    @MainActor
    func testKillNonExistentProcessReturnsError() {
        let service = PortScannerService()
        let fakeEntry = PortEntry(port: 9999, processName: "fake", pid: 2_000_000)

        let result = service.killProcess(entry: fakeEntry)

        XCTAssertNotNil(result)
        XCTAssertEqual(result, "Process already terminated.")
    }
}
