import Foundation
import Observation
import CoreLocation

/// Orchestrates the local pipeline: sampled frame → vision labels → memory-key match →
/// combine with phone context → rule evaluation → single local alert.
///
@MainActor
@Observable
final class ContextEngine {
    // Signals surfaced to the UI.
    var latestLabels: [String] = []
    var matchedKeyNames: [String] = []
    var lastEventDescription: String?

    private let capture: MockCaptureService
    private let vision: VisionService
    private let store: MemoryStore
    private let notifier: NotificationService
    private let location: any LocationContextProvider
    private let evaluator = RuleEvaluator()
    private var lastMatchedKeyIDs: Set<UUID> = []
    private var locationRevision = 0

    init(
        capture: MockCaptureService,
        vision: VisionService,
        store: MemoryStore,
        notifier: NotificationService,
        location: any LocationContextProvider
    ) {
        self.capture = capture
        self.vision = vision
        self.store = store
        self.notifier = notifier
        self.location = location
        capture.onFrame = { [weak self] frame in
            self?.handle(frame: frame)
        }
        location.onContextChange = { [weak self] in
            self?.locationDidChange()
        }
    }

    var isAtHome: Bool { _ = locationRevision; return location.isAtHome }
    var isDepartingContext: Bool { _ = locationRevision; return location.isDepartingContext }
    var homeLocation: HomeLocation? { _ = locationRevision; return location.homeLocation }
    var locationAuthorizationStatus: CLAuthorizationStatus { _ = locationRevision; return location.authorizationStatus }

    func requestLocationAuthorization() { location.requestWhenInUseAuthorization() }
    func setHomeToCurrentLocation() { location.setHomeToCurrentLocation() }
    func clearHomeLocation() { location.clearHomeLocation() }

    var isStreaming: Bool { capture.isStreaming }

    func setScriptedLabels(_ labels: [String]) {
        capture.scriptedLabels = labels
    }

    func startStreaming() {
        capture.start()
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
        lastMatchedKeyIDs = matchedIDs
        matchedKeyNames = store.memoryKeys()
            .filter { matchedIDs.contains($0.id) }
            .map(\.name)
        evaluate(matchedKeyIDs: matchedIDs)
    }

    private func locationDidChange() {
        locationRevision += 1
        evaluate(matchedKeyIDs: lastMatchedKeyIDs)
    }

    /// Evaluate every active reminder against the current context and deliver alerts.
    func evaluate(matchedKeyIDs: Set<UUID>) {
        let snapshot = ContextSnapshot(
            isAtHome: location.isAtHome,
            isDepartingContext: location.isDepartingContext,
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
