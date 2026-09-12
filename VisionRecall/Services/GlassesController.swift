import Foundation
import UIKit
import Observation

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

enum GlassesError: LocalizedError {
    case notConnected
    case permissionDenied
    case cameraUnavailable
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Glasses are not connected."
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
    /// Launch the one-time registration flow (deep-links to the Meta AI app).
    func startRegistration() async throws
    func connect() async throws
    func capturePhoto() async throws -> UIImage
    func disconnect()
}

/// Observable model the Home screen binds to. Holds status + the latest photo and
/// delegates the actual work to a swappable `GlassesBackend`.
@MainActor
@Observable
final class GlassesController {
    private(set) var status: GlassesStatus = .disconnected
    private(set) var latestPhoto: UIImage?
    private(set) var lastCaptureDate: Date?

    private let backend: GlassesBackend

    init(backend: GlassesBackend = GlassesBackendFactory.make()) {
        self.backend = backend
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
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    func disconnect() {
        backend.disconnect()
        status = .disconnected
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
