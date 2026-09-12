import Foundation
import Vision

/// Produces compact on-device labels for a frame. Kept behind a protocol so the demo can
/// substitute scripted labels for real classification.
protocol VisionService {
    func labels(for frame: CameraFrame) -> [String]
}

/// Default implementation.
///
/// If a frame carries scripted labels (mock/demo path), those are returned directly.
/// Otherwise it runs Vision's built-in image classifier on-device and returns the
/// most-confident labels. No image ever leaves the device.
struct DefaultVisionService: VisionService {
    /// Minimum classifier confidence to accept a label.
    var minimumConfidence: Float = 0.2
    /// Maximum labels returned per frame.
    var maxLabels: Int = 5

    func labels(for frame: CameraFrame) -> [String] {
        if !frame.simulatedLabels.isEmpty {
            return frame.simulatedLabels
        }
        guard let cgImage = frame.image.cgImage else { return [] }

        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return []
        }
        let observations = request.results ?? []
        return observations
            .filter { $0.confidence >= minimumConfidence }
            .prefix(maxLabels)
            .map { $0.identifier }
    }
}
