import Foundation
import Darwin

@Observable
@MainActor
public final class PortScannerService {
    public var entries: [PortEntry] = []
    public var isScanning = false
    public var lastError: String?

    public init() {}

    public func scan() {
        isScanning = true
        lastError = nil

        Task.detached {
            let result = Self.runLsof()
            await MainActor.run {
                switch result {
                case .success(let parsed):
                    self.entries = parsed
                case .failure(let error):
                    self.lastError = error.localizedDescription
                }
                self.isScanning = false
            }
        }
    }

    public func scanSync() {
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

    public func killProcess(entry: PortEntry) -> String? {
        let result = Darwin.kill(entry.pid, SIGTERM)
        if result == 0 {
            return nil
        }
        switch errno {
        case EPERM:
            return "Permission denied — process owned by another user."
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

        return .success(LsofParser.parse(output))
    }
}
