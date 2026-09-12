import Foundation

/// Hardware-independent trigger rule consumed by `RuleEvaluator`.
struct ReminderRule: Equatable, Sendable {
    var requiredKeyIDs: Set<UUID>
    var requiresHome: Bool
    var requiresDepartingContext: Bool
    var allowedHourRange: ClosedRange<Int>?
    var confidenceThreshold: Double

    // Signal weights. A visual match alone is intentionally not enough to cross a
    // sensible threshold — visual evidence is one input, combined with phone context.
    static let visualWeight = 0.4
    static let homeWeight = 0.3
    static let departingWeight = 0.3
}

/// The result of evaluating one reminder against a context snapshot.
enum EvaluationOutcome: Equatable, Sendable {
    /// Outside the reminder's allowed time window — hard gate, no alert.
    case outsideTimeWindow
    /// Already delivered once; suppressed to avoid duplicates.
    case alreadyDelivered
    /// Signals combined below the confidence threshold.
    case belowThreshold(score: Double)
    /// Confidence met or exceeded the threshold — deliver a single local alert.
    case shouldNotify(score: Double)
}

/// Combines visual, time, and phone-context signals into a confidence score and
/// decides whether a reminder should fire. Pure and side-effect free so it can be
/// unit-tested without camera hardware or persistence.
struct RuleEvaluator {

    func evaluate(
        rule: ReminderRule,
        context: ContextSnapshot,
        alreadyDelivered: Bool
    ) -> EvaluationOutcome {
        if alreadyDelivered {
            return .alreadyDelivered
        }

        // Time window is a hard gate, not a weighted signal.
        if let window = rule.allowedHourRange, !window.contains(context.hour) {
            return .outsideTimeWindow
        }

        let score = confidence(rule: rule, context: context)
        if score >= rule.confidenceThreshold {
            return .shouldNotify(score: score)
        }
        return .belowThreshold(score: score)
    }

    /// Weighted confidence over only the signals the rule actually requires,
    /// normalized so that satisfying every required signal yields 1.0.
    func confidence(rule: ReminderRule, context: ContextSnapshot) -> Double {
        var totalWeight = 0.0
        var satisfiedWeight = 0.0

        if !rule.requiredKeyIDs.isEmpty {
            totalWeight += ReminderRule.visualWeight
            if rule.requiredKeyIDs.isSubset(of: context.matchedKeyIDs) {
                satisfiedWeight += ReminderRule.visualWeight
            }
        }

        if rule.requiresHome {
            totalWeight += ReminderRule.homeWeight
            if context.isAtHome {
                satisfiedWeight += ReminderRule.homeWeight
            }
        }

        if rule.requiresDepartingContext {
            totalWeight += ReminderRule.departingWeight
            if context.isDepartingContext {
                satisfiedWeight += ReminderRule.departingWeight
            }
        }

        // A rule with no configured signals never fires on its own.
        guard totalWeight > 0 else { return 0 }
        return satisfiedWeight / totalWeight
    }
}
