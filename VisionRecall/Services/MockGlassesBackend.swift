import Foundation
import UIKit

/// Simulator/test backend. Simulates connecting to glasses and returns a generated
/// placeholder photo so the Home screen and demo work without hardware.
@MainActor
final class MockGlassesBackend: GlassesBackend {
    private var captureCount = 0

    func startRegistration() async throws {
        // No registration needed for the mock; the simulator has no glasses to pair.
    }

    func connect() async throws {
        try? await Task.sleep(for: .milliseconds(600))
    }

    func capturePhoto() async throws -> UIImage {
        try? await Task.sleep(for: .milliseconds(400))
        captureCount += 1
        return Self.placeholderPhoto(index: captureCount)
    }

    func disconnect() {}

    func diagnostics() async -> String {
        "Simulator: MockGlassesBackend (no real SDK devices)."
    }

    private static func placeholderPhoto(index: Int) -> UIImage {
        let size = CGSize(width: 720, height: 1280)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let colors = [UIColor.systemIndigo, UIColor.systemTeal]
            colors[index % colors.count].setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let text = "Mock glasses photo #\(index)\n\(Date.now.formatted(date: .omitted, time: .standard))"
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 40, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: style
            ]
            let rect = CGRect(x: 20, y: size.height / 2 - 60, width: size.width - 40, height: 160)
            (text as NSString).draw(in: rect, withAttributes: attrs)
        }
    }
}
