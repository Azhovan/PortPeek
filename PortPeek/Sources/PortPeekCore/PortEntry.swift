import Foundation

public struct PortEntry: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let port: Int
    public let processName: String
    public let pid: Int32

    public init(port: Int, processName: String, pid: Int32) {
        self.id = UUID()
        self.port = port
        self.processName = processName
        self.pid = pid
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(port)
        hasher.combine(pid)
    }

    public static func == (lhs: PortEntry, rhs: PortEntry) -> Bool {
        lhs.port == rhs.port && lhs.pid == rhs.pid
    }

    public static func filter(_ entries: [PortEntry], by searchText: String) -> [PortEntry] {
        guard !searchText.isEmpty else { return entries }
        let query = searchText.lowercased()
        return entries.filter { entry in
            String(entry.port).contains(query) ||
            entry.processName.lowercased().contains(query)
        }
    }
}
