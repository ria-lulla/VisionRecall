import SwiftUI

/// Home screen: connect to the glasses, capture a photo, and show the latest one.
struct HomeView: View {
    @Environment(GlassesController.self) private var glasses

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                photo
                statusRow
                controls
                diagnosticsSection
                Spacer()
            }
            .padding()
            .navigationTitle("VisionRecall")
        }
    }

    private var photo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.quaternary)
            if let image = glasses.latestPhoto {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ContentUnavailableView(
                    "No photo yet",
                    systemImage: "camera.viewfinder",
                    description: Text("Connect your glasses and capture a photo.")
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 420)
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            Text(glasses.status.label)
                .foregroundStyle(.secondary)
            if let date = glasses.lastCaptureDate {
                Spacer()
                Text(date.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .font(.subheadline)
    }

    @ViewBuilder
    private var controls: some View {
        switch glasses.status {
        case .disconnected, .failed, .registering:
            Button {
                Task { await glasses.connect() }
            } label: {
                Label("Connect glasses", systemImage: "eyeglasses")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(glasses.status == .registering)

            Button {
                Task { await glasses.startRegistration() }
            } label: {
                Label("Register glasses", systemImage: "link")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Text("First time? Tap Register to link VisionRecall in the Meta AI app, then Connect.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        default:
            Button {
                Task { await glasses.capturePhoto() }
            } label: {
                Label("Capture photo", systemImage: "camera")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(glasses.status.isBusy)

            Button("Disconnect", role: .destructive) {
                glasses.disconnect()
            }
        }
    }

    @ViewBuilder
    private var diagnosticsSection: some View {
        VStack(spacing: 6) {
            Button("Check devices") {
                Task { await glasses.refreshDiagnostics() }
            }
            .font(.caption)

            if !glasses.diagnostics.isEmpty {
                ScrollView(.vertical) {
                    Text(glasses.diagnostics)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 140)
            }
        }
    }

    private var statusColor: Color {
        switch glasses.status {
        case .ready: return .green
        case .connecting, .capturing, .registering: return .orange
        case .failed: return .red
        case .disconnected: return .gray
        }
    }
}
