import Foundation
import UIKit

// The real Meta Wearables Device Access Toolkit adapter.
//
// This file only compiles once the SDK is added via Swift Package Manager
// (https://github.com/facebook/meta-wearables-dat-ios), so the app builds green on the
// mock path today. Add the package, then this adapter becomes active automatically.
//
// API shapes below follow the current DAT iOS integration guide:
//   - StreamConfiguration(videoCodec:resolution:frameRate:)  frameRate ∈ {2,7,15,24,30}
//   - session.addCamera(config:) -> Camera?
//   - camera.stream.videoFramePublisher.listen { frame in frame.makeUIImage() }
//   - camera.stream.statePublisher.listen { state in ... }
//   - camera.stream.start()

#if canImport(MWDATCore) && canImport(MWDATCamera)
import MWDATCore
import MWDATCamera

@MainActor
final class MetaCaptureService: CaptureService {
    private(set) var isStreaming = false
    var onFrame: ((CameraFrame) -> Void)?

    private let session: DeviceSession
    private var stream: CameraStream?
    private var frameToken: ListenerToken?
    private var stateToken: ListenerToken?

    /// Inject an established `DeviceSession` (created after `Wearables.initialize` and
    /// a granted camera permission from the Meta AI app).
    init(session: DeviceSession) {
        self.session = session
    }

    func start() throws {
        guard !isStreaming else { return }
        let config = StreamConfiguration(
            videoCodec: .raw,
            resolution: .low,   // low first: less Bluetooth compression, sharper frames
            frameRate: 7        // conservative sampling rate for reminder matching
        )
        guard let camera = try session.addCamera(config: config) else { return }
        let stream = camera.stream
        self.stream = stream

        stateToken = stream.statePublisher.listen { [weak self] state in
            Task { @MainActor in
                self?.isStreaming = (state == .streaming)
            }
        }
        frameToken = stream.videoFramePublisher.listen { [weak self] frame in
            guard let image = frame.makeUIImage() else { return }
            Task { @MainActor in
                self?.onFrame?(CameraFrame(image: image))
            }
        }
        stream.start()
        isStreaming = true
    }

    func stop() {
        stream?.stop()
        frameToken = nil
        stateToken = nil
        stream = nil
        isStreaming = false
    }
}
#endif
