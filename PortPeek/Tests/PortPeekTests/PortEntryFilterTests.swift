import XCTest
@testable import PortPeekCore

final class PortEntryFilterTests: XCTestCase {

    private let entries = [
        PortEntry(port: 3000, processName: "node", pid: 100),
        PortEntry(port: 5173, processName: "vite", pid: 200),
        PortEntry(port: 8080, processName: "go-server", pid: 300),
        PortEntry(port: 5432, processName: "postgres", pid: 400),
        PortEntry(port: 3306, processName: "mysqld", pid: 500),
    ]

    func testEmptySearchReturnsAll() {
        let result = PortEntry.filter(entries, by: "")
        XCTAssertEqual(result.count, 5)
    }

    func testFilterByExactPort() {
        let result = PortEntry.filter(entries, by: "3000")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].port, 3000)
    }

    func testFilterByPartialPort() {
        let result = PortEntry.filter(entries, by: "80")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].port, 8080)
    }

    func testFilterByPortPrefixMatchesMultiple() {
        let result = PortEntry.filter(entries, by: "30")
        XCTAssertEqual(result.count, 2)
        let ports = result.map(\.port)
        XCTAssertTrue(ports.contains(3000))
        XCTAssertTrue(ports.contains(3306))
    }

    func testFilterByProcessNameExact() {
        let result = PortEntry.filter(entries, by: "node")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].processName, "node")
    }

    func testFilterByProcessNamePartial() {
        let result = PortEntry.filter(entries, by: "go")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].processName, "go-server")
    }

    func testFilterIsCaseInsensitive() {
        let result = PortEntry.filter(entries, by: "NODE")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].processName, "node")
    }

    func testFilterMixedCaseProcessName() {
        let entries = [PortEntry(port: 9000, processName: "GoServer", pid: 1)]
        let result = PortEntry.filter(entries, by: "goserver")
        XCTAssertEqual(result.count, 1)
    }

    func testFilterNoMatchReturnsEmpty() {
        let result = PortEntry.filter(entries, by: "nginx")
        XCTAssertTrue(result.isEmpty)
    }

    func testFilterWhitespaceOnlyReturnsEmpty() {
        let result = PortEntry.filter(entries, by: " ")
        XCTAssertTrue(result.isEmpty)
    }

    func testFilterEmptyEntriesReturnsEmpty() {
        let result = PortEntry.filter([], by: "node")
        XCTAssertTrue(result.isEmpty)
    }

    func testFilterEmptyEntriesEmptySearchReturnsEmpty() {
        let result = PortEntry.filter([], by: "")
        XCTAssertTrue(result.isEmpty)
    }

    func testFilterMatchesPortAsSubstring() {
        let result = PortEntry.filter(entries, by: "517")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].port, 5173)
    }

    func testFilterMatchesProcessNameSubstring() {
        let result = PortEntry.filter(entries, by: "sql")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].processName, "mysqld")
    }
}
