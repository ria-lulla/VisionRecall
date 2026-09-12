import XCTest
@testable import VisionRecall

final class RuleEvaluatorTests: XCTestCase {
    private let evaluator = RuleEvaluator()
    private let boxes = UUID()

    /// The canonical demo rule: at home + door/exit + boxes seen, within 7–10h.
    private func boxesRule(threshold: Double = 0.7) -> ReminderRule {
        ReminderRule(
            requiredKeyIDs: [boxes],
            requiresHome: true,
            requiresDepartingContext: true,
            allowedHourRange: 7...10,
            confidenceThreshold: threshold
        )
    }

    private func snapshot(
        hour: Int = 8,
        home: Bool,
        departing: Bool,
        matched: Set<UUID>
    ) -> ContextSnapshot {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 1; comps.day = 1; comps.hour = hour
        let date = Calendar.current.date(from: comps)!
        return ContextSnapshot(
            timestamp: date,
            isAtHome: home,
            isDepartingContext: departing,
            matchedKeyIDs: matched
        )
    }

    func testReminderTriggersWhenBoxesHomeAndDoorSignalsMatch() {
        let outcome = evaluator.evaluate(
            rule: boxesRule(),
            context: snapshot(home: true, departing: true, matched: [boxes]),
            alreadyDelivered: false
        )
        XCTAssertEqual(outcome, .shouldNotify(score: 1.0))
    }

    func testVisualMatchAloneDoesNotTrigger() {
        // Boxes seen, but not home and not leaving: visual is one input, not enough.
        let outcome = evaluator.evaluate(
            rule: boxesRule(),
            context: snapshot(home: false, departing: false, matched: [boxes]),
            alreadyDelivered: false
        )
        XCTAssertEqual(outcome, .belowThreshold(score: 0.4))
    }

    func testHomeAndDoorWithoutVisualStaysBelowThreshold() {
        // Context without the visual key should not reach the 0.7 threshold.
        let outcome = evaluator.evaluate(
            rule: boxesRule(),
            context: snapshot(home: true, departing: true, matched: []),
            alreadyDelivered: false
        )
        XCTAssertEqual(outcome, .belowThreshold(score: 0.6))
    }

    func testOutsideTimeWindowNeverTriggers() {
        let outcome = evaluator.evaluate(
            rule: boxesRule(),
            context: snapshot(hour: 23, home: true, departing: true, matched: [boxes]),
            alreadyDelivered: false
        )
        XCTAssertEqual(outcome, .outsideTimeWindow)
    }

    func testDoesNotRetriggerAfterDelivered() {
        let outcome = evaluator.evaluate(
            rule: boxesRule(),
            context: snapshot(home: true, departing: true, matched: [boxes]),
            alreadyDelivered: true
        )
        XCTAssertEqual(outcome, .alreadyDelivered)
    }

    func testRuleWithNoSignalsNeverFires() {
        let rule = ReminderRule(
            requiredKeyIDs: [],
            requiresHome: false,
            requiresDepartingContext: false,
            allowedHourRange: nil,
            confidenceThreshold: 0.7
        )
        let outcome = evaluator.evaluate(
            rule: rule,
            context: snapshot(home: true, departing: true, matched: [boxes]),
            alreadyDelivered: false
        )
        XCTAssertEqual(outcome, .belowThreshold(score: 0.0))
    }
}
