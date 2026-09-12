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

    func connect() async throws {
        // Access Wearables lazily here — never at init — so GlassesRuntime.configure()
        // (called at app launch) always runs first.
        let wearables = Wearables.shared
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
}
#endif
