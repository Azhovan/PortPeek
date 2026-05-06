import XCTest
@testable import PortPeekCore

final class LsofParserTests: XCTestCase {

    static let sampleOutput = """
    COMMAND     PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
    ControlCe  2500 jabar    9u  IPv4 0xe95f3acf21390d      0t0  TCP *:7000 (LISTEN)
    node      12421 jabar   22u  IPv6 0xa1b2c3d4e5f6a7      0t0  TCP *:3000 (LISTEN)
    vite      44219 jabar   18u  IPv4 0xb2c3d4e5f6a7b8      0t0  TCP 127.0.0.1:5173 (LISTEN)
    go-server 88731 jabar    3u  IPv6 0xc3d4e5f6a7b8c9      0t0  TCP *:8080 (LISTEN)
    """

    func testParsesStandardOutput() {
        let entries = LsofParser.parse(Self.sampleOutput)
        XCTAssertEqual(entries.count, 4)
    }

    func testExtractsPortsCorrectly() {
        let entries = LsofParser.parse(Self.sampleOutput)
        let ports = entries.map(\.port)
        XCTAssertEqual(ports, [3000, 5173, 7000, 8080])
    }

    func testExtractsProcessNames() {
        let entries = LsofParser.parse(Self.sampleOutput)
        let names = entries.map(\.processName)
        XCTAssertTrue(names.contains("node"))
        XCTAssertTrue(names.contains("vite"))
        XCTAssertTrue(names.contains("go-server"))
        XCTAssertTrue(names.contains("ControlCe"))
    }

    func testExtractsPIDs() {
        let entries = LsofParser.parse(Self.sampleOutput)
        let pids = entries.map(\.pid)
        XCTAssertTrue(pids.contains(2500))
        XCTAssertTrue(pids.contains(12421))
        XCTAssertTrue(pids.contains(44219))
        XCTAssertTrue(pids.contains(88731))
    }

    func testResultsSortedByPort() {
        let entries = LsofParser.parse(Self.sampleOutput)
        let ports = entries.map(\.port)
        XCTAssertEqual(ports, ports.sorted())
    }

    func testDeduplicatesSamePortAndPID() {
        let output = """
        COMMAND   PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        node    12421 jabar   22u  IPv4 0xa1b2c3d4e5f6a7      0t0  TCP *:3000 (LISTEN)
        node    12421 jabar   23u  IPv6 0xb2c3d4e5f6a7b8      0t0  TCP *:3000 (LISTEN)
        """

        let entries = LsofParser.parse(output)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].port, 3000)
        XCTAssertEqual(entries[0].pid, 12421)
    }

    func testKeepsDifferentPIDsSamePort() {
        let output = """
        COMMAND   PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        node    12421 jabar   22u  IPv4 0xa1b2c3d4e5f6a7      0t0  TCP *:3000 (LISTEN)
        node    12422 jabar   23u  IPv4 0xb2c3d4e5f6a7b8      0t0  TCP *:3000 (LISTEN)
        """

        let entries = LsofParser.parse(output)
        XCTAssertEqual(entries.count, 2)
    }

    func testHandlesEmptyOutput() {
        let entries = LsofParser.parse("")
        XCTAssertTrue(entries.isEmpty)
    }

    func testHandlesHeaderOnly() {
        let output = "COMMAND     PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME\n"
        let entries = LsofParser.parse(output)
        XCTAssertTrue(entries.isEmpty)
    }

    func testHandlesMalformedLines() {
        let output = """
        COMMAND     PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        short line
        node    abc jabar   22u  IPv4 0xa1b2c3d4e5f6a7      0t0  TCP *:3000 (LISTEN)
        vite   44219 jabar   18u  IPv4 0xb2c3d4e5f6a7b8      0t0  TCP 127.0.0.1:5173 (LISTEN)
        """

        let entries = LsofParser.parse(output)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].processName, "vite")
    }

    func testParsesLocalhostBound() {
        let output = """
        COMMAND   PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        node    1234 jabar   22u  IPv4 0xa1b2c3d4e5f6a7      0t0  TCP 127.0.0.1:4000 (LISTEN)
        """

        let entries = LsofParser.parse(output)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].port, 4000)
    }

    func testParsesWildcardBound() {
        let output = """
        COMMAND   PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        node    1234 jabar   22u  IPv6 0xa1b2c3d4e5f6a7      0t0  TCP *:9000 (LISTEN)
        """

        let entries = LsofParser.parse(output)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].port, 9000)
    }

    func testIgnoresHexDeviceColumnContainingColon() {
        let output = """
        COMMAND   PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        node    1234 jabar   22u  IPv4 0xe95f:3acf21390d      0t0  TCP *:8080 (LISTEN)
        """

        let entries = LsofParser.parse(output)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].port, 8080)
    }

    func testHandlesHighPortNumbers() {
        let output = """
        COMMAND   PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        node    1234 jabar   22u  IPv4 0xa1b2c3d4e5f6a7      0t0  TCP *:65535 (LISTEN)
        """

        let entries = LsofParser.parse(output)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].port, 65535)
    }

    func testHandlesLongProcessNames() {
        let output = """
        COMMAND              PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        com.docker.backend  3923 jabar   22u  IPv4 0xa1b2c3d4e5f6a7      0t0  TCP *:8080 (LISTEN)
        """

        let entries = LsofParser.parse(output)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].processName, "com.docker.backend")
    }
}
