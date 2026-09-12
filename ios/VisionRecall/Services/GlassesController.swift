import Foundation
import UIKit
import Observation
import VisionRecallMemory

/// Connection/capture state surfaced to the UI.
enum GlassesStatus: Equatable {
    case disconnected
    case registering
    case connecting
    case ready
    case capturing
    case failed(String)

    var label: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .registering: return "Registering… finish in the Meta AI app"
        case .connecting: return "Connecting…"
        case .ready: return "Ready"
        case .capturing: return "Capturing…"
        case .failed(let message): return "Error: \(message)"
        }
    }

    var isBusy: Bool { self == .connecting || self == .capturing || self == .registering }
}

/// Mirrors the SDK's RegistrationState so the UI never imports the SDK.
enum GlassesRegistrationState: String {
    case unknown
    case unavailable
    case available
    case registering
    case registered
}

enum GlassesError: LocalizedError {
    case notConnected
    case notEligible(String)
    case permissionDenied
    case cameraUnavailable
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Glasses are not connected."
        case .notEligible(let detail): return detail
        case .permissionDenied: return "Camera permission was denied in the Meta AI app."
        case .cameraUnavailable: return "The glasses camera is unavailable."
        case .decodeFailed: return "Could not decode the captured photo."
        }
    }
}

/// Hardware-agnostic backend the UI never talks to directly. Implemented by the mock
/// (simulator/tests) and the real Meta DAT adapter (device).
@MainActor
protocol GlassesBackend: AnyObject {
    /// Begin observing the SDK's registration state. Call after `Wearables.configure()`.
    func observeRegistration(onChange: @escaping @MainActor (GlassesRegistrationState) -> Void)
    /// Launch the one-time registration flow (deep-links to the Meta AI app).
    func startRegistration() async throws
    func connect() async throws
    func capturePhoto() async throws -> UIImage
    func disconnect()
    /// Human-readable dump of what the SDK currently reports, for troubleshooting.
    func diagnostics() async -> String
}

/// Observable model the Home screen binds to. Holds status + the latest photo and
/// delegates the actual work to a swappable `GlassesBackend`.
@MainActor
@Observable
final class GlassesController {
    private(set) var status: GlassesStatus = .disconnected
    private(set) var latestPhoto: UIImage?
    private(set) var lastCaptureDate: Date?
    private(set) var diagnostics: String = ""
    private(set) var registrationState: GlassesRegistrationState = .unknown

    private let backend: GlassesBackend
    private let captureStore: (any CaptureStoring)?

    init(
        backend: GlassesBackend = GlassesBackendFactory.make(),
        captureStore: (any CaptureStoring)? = nil
    ) {
        self.backend = backend
        self.captureStore = captureStore
    }

    /// Start watching registration state. Call once, after the SDK is configured.
    func activate() {
        backend.observeRegistration { [weak self] state in
            guard let self else { return }
            self.registrationState = state
            // Don't leave the UI stuck on "Registering…" once the SDK reports a
            // terminal state.
            switch state {
            case .registered:
                if self.status == .registering { self.status = .disconnected }
            case .available, .unavailable:
                if self.status == .registering {
                    self.status = state == .unavailable
                        ? .failed("Registration unavailable. Check the Meta AI app and your connection.")
                        : .disconnected
                }
            case .registering, .unknown:
                break
            }
        }
    }

    /// One-time: connect this app to the glasses via the Meta AI app. After returning
    /// from the Meta AI app, tap Connect.
    func startRegistration() async {
        status = .registering
        do {
            try await backend.startRegistration()
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    func connect() async {
        guard status != .connecting else { return }
        status = .connecting
        do {
            try await backend.connect()
            status = .ready
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    func capturePhoto() async {
        // Allow capture from a ready state (or retry after a prior capture).
        guard case .ready = status else { return }
        status = .capturing
        do {
            let image = try await backend.capturePhoto()
            latestPhoto = image
            lastCaptureDate = .now
            status = .ready
            await persist(image)
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    func disconnect() {
        backend.disconnect()
        status = .disconnected
    }

    /// Save the capture to the bounded, backup-excluded on-device gallery. A storage
    /// failure must not fail the capture the user just took.
    private func persist(_ image: UIImage) async {
        guard let captureStore, let data = image.jpegData(compressionQuality: 0.8) else { return }
        do {
            _ = try await captureStore.save(imageData: data, capturedAt: .now)
        } catch {
            GlassesLog.error("Failed to persist capture: \(error)")
        }
    }

    func refreshDiagnostics() async {
        diagnostics = "Checking…"
        diagnostics = await backend.diagnostics()
    }
}

/// Picks the backend for the current runtime: the mock on Simulator (and where the SDK
/// is absent), the real Meta adapter on a physical device.
enum GlassesBackendFactory {
    @MainActor
    static func make() -> GlassesBackend {
        #if canImport(MWDATCore) && !targetEnvironment(simulator)
        return MetaGlassesBackend()
        #else
        return MockGlassesBackend()
        #endif
    }
}
