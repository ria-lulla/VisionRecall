import Foundation
import SwiftData

/// A visual "memory key" the user has registered, such as a front door or a stack of boxes.
///
/// Keys are matched against on-device vision labels. We deliberately persist only compact
/// matching data (a label and optional descriptor), never raw frames.
@Model
final class MemoryKey {
    @Attribute(.unique) var id: UUID
    /// Human-facing name shown in the UI, e.g. "Front door".
    var name: String
    /// The primary label the vision service should match, e.g. "door".
    var label: String
    /// Additional labels that also count as a match, lowercased at match time.
    var aliases: [String]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        label: String,
        aliases: [String] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.label = label
        self.aliases = aliases
        self.createdAt = createdAt
    }

    /// Returns true if any of the detected vision labels matches this key.
    func matches(labels: [String]) -> Bool {
        let needles = VisionLabelMapper.labels(for: [label] + aliases, limit: .max)
        let haystack = VisionLabelMapper.labels(for: labels, limit: .max)
        return needles.contains { needle in
            haystack.contains { candidate in
                candidate == needle || candidate.split(separator: " ").contains(Substring(needle))
            }
        }
    }
}
