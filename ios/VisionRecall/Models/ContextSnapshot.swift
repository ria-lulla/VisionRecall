import Foundation

/// A point-in-time view of the local signals the rule evaluator combines.
///
/// This intentionally holds only compact, derived data — matched key IDs and coarse
/// context flags — never raw frames.
struct ContextSnapshot: Equatable, Sendable {
    var timestamp: Date
    /// Whether the phone considers the user at home.
    var isAtHome: Bool
    /// Whether a door/exit ("about to leave") context is currently detected.
    var isDepartingContext: Bool
    /// Visual memory keys currently matched by the vision service.
    var matchedKeyIDs: Set<UUID>

    init(
        timestamp: Date = .now,
        isAtHome: Bool = false,
        isDepartingContext: Bool = false,
        matchedKeyIDs: Set<UUID> = []
    ) {
        self.timestamp = timestamp
        self.isAtHome = isAtHome
        self.isDepartingContext = isDepartingContext
        self.matchedKeyIDs = matchedKeyIDs
    }

    /// Local hour-of-day (0...23) used for time-window gating.
    var hour: Int {
        Calendar.current.component(.hour, from: timestamp)
    }
}
