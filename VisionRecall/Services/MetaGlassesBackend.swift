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

        // A device is only eligible once its link state is `.connected`, so wait for a
        // connected device and select it explicitly rather than relying on
        // AutoDeviceSelector picking the right one.
        guard let deviceId = await Self.waitForConnectedDevice(timeout: .seconds(20)) else {
            throw GlassesError.notEligible(Self.eligibilitySummary())
        }

        let selector = SpecificDeviceSelector(device: deviceId)
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

    /// Reports what the SDK currently knows: registration, each known device, its link
    /// state and compatibility. `devices` is a synchronous property, so unlike
    /// `devicesStream()` this always returns immediately.
    func diagnostics() async -> String {
        let wearables = Wearables.shared
        var lines = ["registration: \(wearables.registrationState)"]

        let ids = wearables.devices
        lines.append("devices: \(ids.count)")
        for id in ids {
            guard let device = wearables.deviceForIdentifier(id) else {
                lines.append("- \(id): no Device object")
                continue
            }
            lines.append("- \(device.nameOrId())")
            lines.append("    type: \(device.deviceType().rawValue)")
            lines.append("    link: \(device.linkState)")
            lines.append("    compat: \(device.compatibility().displayString)")
        }
        if ids.isEmpty {
            lines.append("The SDK sees no glasses. Confirm they're connected in the Meta AI app.")
        }
        return lines.joined(separator: "\n")
    }

    /// Explains why no device was eligible, using link state and compatibility.
    private static func eligibilitySummary() -> String {
        let wearables = Wearables.shared
        let ids = wearables.devices
        guard !ids.isEmpty else {
            return "No glasses are known to the SDK. Make sure they're connected in the Meta AI app."
        }
        let details = ids.map { id -> String in
            guard let device = wearables.deviceForIdentifier(id) else { return "\(id): unknown" }
            return "\(device.nameOrId()) [link: \(device.linkState), compat: \(device.compatibility().displayString)]"
        }
        return "No connected glasses. " + details.joined(separator: "; ")
    }

    /// Polls for a device whose link state is `.connected`, up to `timeout`.
    private static func waitForConnectedDevice(timeout: Duration) async -> DeviceIdentifier? {
        func connectedDevice() -> DeviceIdentifier? {
            let wearables = Wearables.shared
            return wearables.devices.first { id in
                wearables.deviceForIdentifier(id)?.linkState == .connected
            }
        }

        if let id = connectedDevice() { return id }
        let attempts = max(1, Int(timeout / .milliseconds(500)))
        for _ in 0..<attempts {
            try? await Task.sleep(for: .milliseconds(500))
            if let id = connectedDevice() { return id }
        }
        return nil
    }
}
#endif
