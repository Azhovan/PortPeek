import SwiftUI

struct PortListView: View {
    @Bindable var scanner: PortScannerService
    @State private var portToKill: PortEntry?
    @State private var killError: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 420, height: 460)
    }

    private var header: some View {
        HStack {
            Image(systemName: "stethoscope")
                .foregroundStyle(.blue)
            Text("PortPeek")
                .font(.headline)
            Spacer()
            Button(action: {}) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var content: some View {
        if scanner.entries.isEmpty {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                Text("No listening ports found")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(scanner.entries) { entry in
                        PortRowView(entry: entry) {}
                        Divider()
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("\(scanner.entries.count) port\(scanner.entries.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Quit") {}
                .buttonStyle(.borderless)
                .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
