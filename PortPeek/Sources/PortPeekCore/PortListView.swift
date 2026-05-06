import SwiftUI
import AppKit

public struct PortListView: View {
    @Bindable var scanner: PortScannerService
    @State private var portToKill: PortEntry?
    @State private var killError: String?
    @State private var searchText = ""
    @State private var pollTimer: Timer?

    public init(scanner: PortScannerService) {
        self.scanner = scanner
    }

    private var filteredEntries: [PortEntry] {
        PortEntry.filter(scanner.entries, by: searchText)
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            searchField
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 420, height: 460)
        .alert("Terminate Process?", isPresented: showKillAlert) {
            Button("Cancel", role: .cancel) { portToKill = nil }
            Button("Terminate", role: .destructive) { performKill() }
        } message: {
            if let entry = portToKill {
                Text("Send SIGTERM to \(entry.processName) (PID \(entry.pid)) on port \(entry.port)?")
            }
        }
        .alert("Error", isPresented: showErrorAlert) {
            Button("OK") { killError = nil }
        } message: {
            Text(killError ?? "")
        }
        .onAppear {
            scanner.scan()
            pollTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                Task { @MainActor in scanner.scan() }
            }
        }
        .onDisappear {
            pollTimer?.invalidate()
            pollTimer = nil
        }
    }

    private var showKillAlert: Binding<Bool> {
        Binding(get: { portToKill != nil }, set: { if !$0 { portToKill = nil } })
    }

    private var showErrorAlert: Binding<Bool> {
        Binding(get: { killError != nil }, set: { if !$0 { killError = nil } })
    }

    private var header: some View {
        HStack {
            Image(systemName: "stethoscope")
                .foregroundStyle(.blue)
            Text("PortPeek")
                .font(.headline)
            Spacer()
            Button(action: { scanner.scan() }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(scanner.isScanning)
            .help("Refresh")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search ports...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var content: some View {
        if scanner.isScanning && scanner.entries.isEmpty {
            Spacer()
            ProgressView("Scanning ports...")
            Spacer()
        } else if scanner.entries.isEmpty {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                Text("No listening ports found")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        } else if filteredEntries.isEmpty {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("No matches for \"\(searchText)\"")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filteredEntries) { entry in
                        PortRowView(entry: entry) {
                            portToKill = entry
                        }
                        Divider()
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }

    private var footer: some View {
        HStack {
            if let error = scanner.lastError {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else if !searchText.isEmpty {
                Text("\(filteredEntries.count) of \(scanner.entries.count) port\(scanner.entries.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(scanner.entries.count) port\(scanner.entries.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.borderless)
                .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func performKill() {
        guard let entry = portToKill else { return }
        if let error = scanner.killProcess(entry: entry) {
            killError = error
        }
        portToKill = nil
        scanner.scan()
    }
}
