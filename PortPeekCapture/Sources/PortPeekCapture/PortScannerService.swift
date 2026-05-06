import Foundation
import Darwin

@Observable
@MainActor
final class PortScannerService {
    var entries: [PortEntry] = []
    var isScanning = false
    var lastError: String?

    func scanSync() {
        isScanning = true
        lastError = nil

        let result = Self.runLsof()
        switch result {
        case .success(let parsed):
            entries = parsed
        case .failure(let error):
            lastError = error.localizedDescription
        }
        isScanning = false
    }

    func killProcess(entry: PortEntry) -> String? {
        let result = Darwin.kill(entry.pid, SIGTERM)
        if result == 0 { return nil }
        switch errno {
        case EPERM:
            return "Permission denied."
        case ESRCH:
            return "Process already terminated."
        default:
            return "Kill failed (errno \(errno))."
        }
    }

    private nonisolated static func runLsof() -> Result<[PortEntry], Error> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-nP", "-c0", "-iTCP", "-sTCP:LISTEN"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return .failure(error)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard let output = String(data: data, encoding: .utf8) else {
            return .success([])
        }

        let lines = output.components(separatedBy: "\n")
        var seen = Set<String>()
        var entries: [PortEntry] = []

        for line in lines.dropFirst() {
            let tokens = line.split(separator: " ", omittingEmptySubsequences: true)
            guard tokens.count >= 9 else { continue }

            let command = String(tokens[0])
            guard let pid = Int32(tokens[1]) else { continue }

            guard let nameToken = tokens.last(where: { $0.contains(":") && !$0.hasPrefix("0x") }) else { continue }
            guard let portString = nameToken.split(separator: ":").last,
                  let port = Int(portString) else { continue }

            let key = "\(port)-\(pid)"
            guard !seen.contains(key) else { continue }
            seen.insert(key)

            entries.append(PortEntry(port: port, processName: command, pid: pid))
        }

        entries.sort { $0.port < $1.port }
        return .success(entries)
    }
}
