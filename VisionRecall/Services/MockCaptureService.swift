import Foundation
import UIKit

/// Drives the capture pipeline without hardware by emitting synthetic frames on a timer.
///
/// This mirrors the Meta toolkit's Mock Device Kit flow: it lets the vision → match →
/// rule-evaluation path run in the Simulator before pairing real glasses.
@MainActor
final class MockCaptureService: CaptureService {
    private(set) var isStreaming = false
    var onFrame: ((CameraFrame) -> Void)?

    /// Labels the next emitted frame should carry, e.g. ["door", "boxes"].
    /// Drive this from the demo UI to simulate what the glasses "see".
    var scriptedLabels: [String] = []

    private let interval: Duration
    private var task: Task<Void, Never>?

    init(interval: Duration = .seconds(2)) {
        self.interval = interval
    }

    func start() {
        guard !isStreaming else { return }
        isStreaming = true
        task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: self?.interval ?? .seconds(2))
                guard let self, self.isStreaming else { break }
                self.emit()
            }
        }
    }

    func stop() {
        isStreaming = false
        task?.cancel()
        task = nil
    }

    /// Emit a single frame immediately (useful for a demo "capture now" button).
    func emit() {
        let frame = CameraFrame(
            image: Self.placeholderImage(labels: scriptedLabels),
            simulatedLabels: scriptedLabels
        )
        onFrame?(frame)
    }

    private static func placeholderImage(labels: [String]) -> UIImage {
        let size = CGSize(width: 360, height: 640)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.systemGray5.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let text = labels.isEmpty ? "mock frame" : labels.joined(separator: ", ")
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            (text as NSString).draw(at: CGPoint(x: 20, y: 300), withAttributes: attrs)
        }
    }
}
