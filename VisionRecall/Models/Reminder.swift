import Foundation
import SwiftData

/// A natural-language reminder plus the trigger rule derived from it.
///
/// The persisted model carries the raw rule fields; `rule` projects them into the
/// hardware-independent `ReminderRule` value type that `RuleEvaluator` consumes.
@Model
final class Reminder {
    @Attribute(.unique) var id: UUID
    /// The spoken/typed reminder, e.g. "Remind me to take out the boxes when I leave home."
    var text: String

    // MARK: Trigger rule

    /// Visual memory keys that must be seen. Empty means "no visual requirement".
    var requiredKeyIDs: [UUID]
    /// Whether the user must currently be at home.
    var requiresHome: Bool
    /// Whether a door/exit ("departing") context must be present.
    var requiresDepartingContext: Bool
    /// Inclusive allowed local-hour window [startHour, endHour]. nil means "any time".
    var startHour: Int?
    var endHour: Int?
    /// Confidence in [0, 1] at or above which the reminder fires.
    var confidenceThreshold: Double

    // MARK: Delivery state

    var isActive: Bool
    /// Set once the reminder has fired so it does not re-alert (duplicate suppression).
    var hasFired: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        text: String,
        requiredKeyIDs: [UUID] = [],
        requiresHome: Bool = false,
        requiresDepartingContext: Bool = false,
        startHour: Int? = nil,
        endHour: Int? = nil,
        confidenceThreshold: Double = 0.7,
        isActive: Bool = true,
        hasFired: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.text = text
        self.requiredKeyIDs = requiredKeyIDs
        self.requiresHome = requiresHome
        self.requiresDepartingContext = requiresDepartingContext
        self.startHour = startHour
        self.endHour = endHour
        self.confidenceThreshold = confidenceThreshold
        self.isActive = isActive
        self.hasFired = hasFired
        self.createdAt = createdAt
    }

    /// Hardware-independent projection used by `RuleEvaluator`.
    var rule: ReminderRule {
        let window: ClosedRange<Int>?
        if let startHour, let endHour, startHour <= endHour {
            window = startHour...endHour
        } else {
            window = nil
        }
        return ReminderRule(
            requiredKeyIDs: Set(requiredKeyIDs),
            requiresHome: requiresHome,
            requiresDepartingContext: requiresDepartingContext,
            allowedHourRange: window,
            confidenceThreshold: confidenceThreshold
        )
    }
}
