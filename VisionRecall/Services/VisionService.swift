import Foundation
import UIKit
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
    var minimumConfidence: Float = 0.35
    /// Maximum labels returned per frame.
    var maxLabels: Int = 6

    func labels(for frame: CameraFrame) -> [String] {
        if !frame.simulatedLabels.isEmpty {
            return frame.simulatedLabels
        }
        guard let cgImage = frame.image.cgImage else { return [] }

        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: CGImagePropertyOrientation(frame.image.imageOrientation),
            options: [:]
        )
        do {
            try handler.perform([request])
        } catch {
            return []
        }
        let observations = request.results ?? []
        let identifiers = observations
            .filter { $0.confidence >= minimumConfidence }
            .prefix(maxLabels)
            .map { $0.identifier }
        return VisionLabelMapper.labels(for: identifiers, limit: maxLabels)
    }
}

/// Converts Vision's human-readable identifiers into stable, matchable labels.
///
/// Vision may return a phrase (such as "cardboard box") or a nearby category
/// (such as "carton"). Expanding those identifiers locally lets a user-created
/// key remain useful without retaining a frame or sending it to a service.
enum VisionLabelMapper {
    private static let equivalentLabels: [String: [String]] = [
        "door": ["door", "doorway", "entrance", "entryway", "exit"],
        "box": ["box", "boxes", "carton", "package", "parcel", "cardboard"]
    ]

    static func labels(for identifiers: [String], limit: Int) -> [String] {
        guard limit > 0 else { return [] }

        var labels: [String] = []
        for identifier in identifiers {
            let normalized = normalizedPhrase(identifier)
            guard !normalized.isEmpty else { continue }

            append(normalized, to: &labels)
            for word in normalized.split(separator: " ").map(String.init) {
                append(word, to: &labels)
                append(singular(word), to: &labels)
                for equivalents in equivalentLabels.values where equivalents.contains(word) {
                    for equivalent in equivalents {
                        append(equivalent, to: &labels)
                    }
                }
            }
        }
        return Array(labels.prefix(limit))
    }

    /// Normalizes user-entered keys and Vision identifiers into comparable words.
    static func normalizedPhrase(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    static func singular(_ word: String) -> String {
        guard word.count > 3 else { return word }
        if word.hasSuffix("ies") { return String(word.dropLast(3)) + "y" }
        if word.hasSuffix("es") { return String(word.dropLast(2)) }
        if word.hasSuffix("s") { return String(word.dropLast()) }
        return word
    }

    private static func append(_ label: String, to labels: inout [String]) {
        guard !label.isEmpty, !labels.contains(label) else { return }
        labels.append(label)
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
