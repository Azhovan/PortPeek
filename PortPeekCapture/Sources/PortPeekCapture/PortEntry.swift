import Foundation

struct PortEntry: Identifiable, Hashable, Sendable {
    let id = UUID()
    let port: Int
    let processName: String
    let pid: Int32

    func hash(into hasher: inout Hasher) {
        hasher.combine(port)
        hasher.combine(pid)
    }

    static func == (lhs: PortEntry, rhs: PortEntry) -> Bool {
        lhs.port == rhs.port && lhs.pid == rhs.pid
    }
}
