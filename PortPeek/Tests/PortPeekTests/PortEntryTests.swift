import XCTest
@testable import PortPeekCore

final class PortEntryTests: XCTestCase {

    func testEqualityBasedOnPortAndPid() {
        let a = PortEntry(port: 3000, processName: "node", pid: 123)
        let b = PortEntry(port: 3000, processName: "node", pid: 123)
        XCTAssertEqual(a, b)
    }

    func testDifferentPortsNotEqual() {
        let a = PortEntry(port: 3000, processName: "node", pid: 123)
        let b = PortEntry(port: 4000, processName: "node", pid: 123)
        XCTAssertNotEqual(a, b)
    }

    func testDifferentPidsNotEqual() {
        let a = PortEntry(port: 3000, processName: "node", pid: 123)
        let b = PortEntry(port: 3000, processName: "node", pid: 456)
        XCTAssertNotEqual(a, b)
    }

    func testSamePortPidDifferentNameAreEqual() {
        let a = PortEntry(port: 3000, processName: "node", pid: 123)
        let b = PortEntry(port: 3000, processName: "nodejs", pid: 123)
        XCTAssertEqual(a, b)
    }

    func testHashableConsistency() {
        let a = PortEntry(port: 8080, processName: "go", pid: 999)
        let b = PortEntry(port: 8080, processName: "go", pid: 999)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func testUsableInSet() {
        let a = PortEntry(port: 3000, processName: "node", pid: 123)
        let b = PortEntry(port: 3000, processName: "node", pid: 123)
        let c = PortEntry(port: 4000, processName: "vite", pid: 456)

        var set = Set<PortEntry>()
        set.insert(a)
        set.insert(b)
        set.insert(c)

        XCTAssertEqual(set.count, 2)
    }
}
