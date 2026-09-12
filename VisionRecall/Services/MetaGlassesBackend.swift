import Foundation
import UIKit

// Real Meta Wearables DAT adapter. Compiled only for a physical device — the Simulator
// uses MockGlassesBackend (there are no glasses to connect to there), which also keeps
// simulator builds/tests independent of the binary SDK.
//
// Flow per the DAT iOS integration guide:
//   Wearables.configure() (at launch) → registration (one-time, user-driven) →
//   createSession(deviceSelector:) → session.start() → requestPermission(.camera) →
//   session.addCamera(config:) → stream.start() → stream.capturePhoto(format:)
//   with the result delivered on stream.photoDataPublisher.

#if canImport(MWDATCore) && canImport(MWDATCamera) && !targetEnvironment(simulator)
import MWDATCore
import MWDATCamera

@MainActor
final class MetaGlassesBackend: GlassesBackend {
    private var tokens: [Any] = []
    private var capture: (() -> Void)?
    private var teardown: (() -> Void)?
    private var photoContinuation: CheckedContinuation<UIImage, Error>?
    private var registrationTask: Task<Void, Never>?

    func observeRegistration(onChange: @escaping @MainActor (GlassesRegistrationState) -> Void) {
        registrationTask?.cancel()
        registrationTask = Task { @MainActor in
            for await state in Wearables.shared.registrationStateStream() {
                let mapped: GlassesRegistrationState
                switch state {
                case .registered: mapped = .registered
                case .available: mapped = .available
                case .registering: mapped = .registering
                case .unavailable: mapped = .unavailable
                default: mapped = .unknown
                }
                onChange(mapped)
            }
        }
    }

    func startRegistration() async throws {
        try await Wearables.shared.startRegistration()
    }

    func connect() async throws {
        // Access Wearables lazily here — never at init — so GlassesRuntime.configure()
        // (called at app launch) always runs first.
        let wearables = Wearables.shared

        // After registration the glasses can take a moment to become eligible.
        // createSession fails with "no eligible device" until one appears in the
        // devices stream, so wait for it (bounded) before selecting a device.
        guard await Self.waitForDevice(timeout: .seconds(20)) else {
            throw GlassesError.noDeviceAvailable
        }

        let selector = AutoDeviceSelector(wearables: wearables)
        let session = try wearables.createSession(deviceSelector: selector)
        try session.start()

        // Wait until the device session is active.
        for await state in session.stateStream() {
            if state == .started { break }
            if state == .stopped { throw GlassesError.notConnected }
        }

        // Camera permission is confirmed through the Meta AI app.
        let permission = try await wearables.requestPermission(.camera)
        guard permission == .granted else { throw GlassesError.permissionDenied }

        let config = StreamConfiguration(
            videoCodec: .raw,
            resolution: .medium,
            frameRate: 7
        )
        guard let camera = try session.addCamera(config: config) else {
            throw GlassesError.cameraUnavailable
        }
        let stream = camera.stream

        let token = stream.photoDataPublisher.listen { [weak self] photoData in
            let image = UIImage(data: photoData.data)
            Task { @MainActor in
                guard let self else { return }
                if let image {
                    self.photoContinuation?.resume(returning: image)
                } else {
                    self.photoContinuation?.resume(throwing: GlassesError.decodeFailed)
                }
                self.photoContinuation = nil
            }
        }
        tokens.append(token)
        capture = { stream.capturePhoto(format: .jpeg) }
        teardown = { stream.stop(); session.stop() }
        stream.start()
    }

    func capturePhoto() async throws -> UIImage {
        guard let capture else { throw GlassesError.notConnected }
        return try await withCheckedThrowingContinuation { continuation in
            photoContinuation = continuation
            capture()
        }
    }

    func disconnect() {
        teardown?()
        tokens.removeAll()
        capture = nil
        teardown = nil
        photoContinuation = nil
    }

    /// Dumps what `devicesStream()` reports so we can tell "no device at all" apart from
    /// "device known but not connected" (AutoDeviceSelector picks the first *connected*
    /// device, so a registered-but-disconnected device is still not eligible).
    func diagnostics() async -> String {
        let task = Task { @MainActor () -> String in
            var lastCount = -1
            for await devices in Wearables.shared.devicesStream() {
                lastCount = devices.count
                if !devices.isEmpty {
                    let dump = devices
                        .map { String(describing: $0) }
                        .joined(separator: "\n---\n")
                    return "devicesStream: \(devices.count) device(s)\n\(dump)"
                }
            }
            return lastCount < 0
                ? "devicesStream: no emission before timeout"
                : "devicesStream: emitted \(lastCount) device(s)"
        }
        let timeout = Task {
            try? await Task.sleep(for: .seconds(8))
            task.cancel()
        }
        let result = await task.value
        timeout.cancel()
        return result
    }

    /// Resolves to `true` once at least one glasses device is available, or `false` if
    /// none appears within `timeout`. Races the devices stream against a timer.
    private static func waitForDevice(timeout: Duration) async -> Bool {
        let deviceTask = Task { @MainActor () -> Bool in
            for await devices in Wearables.shared.devicesStream() {
                if !devices.isEmpty { return true }
            }
            return false
        }
        let timeoutTask = Task {
            try? await Task.sleep(for: timeout)
            deviceTask.cancel()
        }
        let result = await deviceTask.value
        timeoutTask.cancel()
        return result
    }
}
#endif
