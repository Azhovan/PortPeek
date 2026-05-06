import SwiftUI
import AppKit

public struct PortRowView: View {
    let entry: PortEntry
    let onKill: () -> Void

    public init(entry: PortEntry, onKill: @escaping () -> Void) {
        self.entry = entry
        self.onKill = onKill
    }

    public var body: some View {
        HStack(spacing: 12) {
            Text(String(entry.port))
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .frame(width: 55, alignment: .trailing)

            Text(entry.processName)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(minWidth: 80, alignment: .leading)

            Text(verbatim: "PID \(entry.pid)")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)

            Spacer()

            Button(action: copyURL) {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)
            .help("Copy http://localhost:\(entry.port)")

            Button(action: onKill) {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red)
            .help("Terminate process")
        }
        .padding(.vertical, 4)
    }

    private func copyURL() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("http://localhost:\(entry.port)", forType: .string)
    }
}
