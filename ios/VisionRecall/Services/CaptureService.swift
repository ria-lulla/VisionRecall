import Foundation
import UIKit

/// A single sampled frame from the glasses camera (or the mock device).
struct CameraFrame {
    let image: UIImage
    let timestamp: Date
    /// Labels supplied by the mock/demo pipeline. The real vision service ignores this
    /// and derives labels from the image on-device.
    var simulatedLabels: [String]

    init(image: UIImage, timestamp: Date = .now, simulatedLabels: [String] = []) {
        self.image = image
        self.timestamp = timestamp
        self.simulatedLabels = simulatedLabels
    }
}

/// Abstraction over the camera source. The Meta Wearables toolkit lives behind this
/// protocol so a mock implementation can drive tests and demos (see ARCHITECTURE.md).
@MainActor
protocol CaptureService: AnyObject {
    var isStreaming: Bool { get }
    /// Called on the main actor for each sampled frame while streaming.
    var onFrame: ((CameraFrame) -> Void)? { get set }
    func start() throws
    func stop()
}
