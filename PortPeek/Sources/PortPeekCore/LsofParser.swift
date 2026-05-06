import Foundation

public enum LsofParser {
    public static func parse(_ output: String) -> [PortEntry] {
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
        return entries
    }
}
