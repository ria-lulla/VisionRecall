import Foundation
import Observation

/// Orchestrates the local pipeline: sampled frame → vision labels → memory-key match →
/// combine with phone context → rule evaluation → single local alert.
///
/// Location/departure are exposed as manual flags in this first prototype so the demo
/// runs without Core Location; swap `isAtHome`/`isDepartingContext` for a
/// `CLLocationManager`-backed provider later.
@MainActor
@Observable
final class ContextEngine {
    // Signals surfaced to the UI.
    var latestLabels: [String] = []
    var matchedKeyNames: [String] = []
    var isAtHome = true
    var isDepartingContext = false
    var lastEventDescription: String?

    private let capture: MockCaptureService
    private let vision: VisionService
    private let store: MemoryStore
    private let notifier: NotificationService
    private let evaluator = RuleEvaluator()

    init(
        capture: MockCaptureService,
        vision: VisionService,
        store: MemoryStore,
        notifier: NotificationService
    ) {
        self.capture = capture
        self.vision = vision
        self.store = store
        self.notifier = notifier
        capture.onFrame = { [weak self] frame in
            self?.handle(frame: frame)
        }
    }

    var isStreaming: Bool { capture.isStreaming }

    func setScriptedLabels(_ labels: [String]) {
        capture.scriptedLabels = labels
    }

    func startStreaming() {
        try? capture.start()
    }

    func stopStreaming() {
        capture.stop()
    }

    /// Sample a single frame right now (demo "capture" button).
    func captureOnce() {
        capture.emit()
    }

    private func handle(frame: CameraFrame) {
        let labels = vision.labels(for: frame)
        latestLabels = labels
        let matchedIDs = store.matchedKeyIDs(for: labels)
        matchedKeyNames = store.memoryKeys()
            .filter { matchedIDs.contains($0.id) }
            .map(\.name)
        evaluate(matchedKeyIDs: matchedIDs)
    }

    /// Evaluate every active reminder against the current context and deliver alerts.
    func evaluate(matchedKeyIDs: Set<UUID>) {
        let snapshot = ContextSnapshot(
            isAtHome: isAtHome,
            isDepartingContext: isDepartingContext,
            matchedKeyIDs: matchedKeyIDs
        )
        for reminder in store.reminders(activeOnly: true) {
            let outcome = evaluator.evaluate(
                rule: reminder.rule,
                context: snapshot,
                alreadyDelivered: reminder.hasFired
            )
            if case .shouldNotify(let score) = outcome {
                reminder.hasFired = true
                lastEventDescription = "Fired: \(reminder.text) (\(Int(score * 100))%)"
                Task {
                    await notifier.deliver(
                        reminderID: reminder.id,
                        title: "VisionRecall",
                        body: reminder.text
                    )
                }
            }
        }
    }
}
