import Foundation
import UserNotifications

/// Sends a single local notification per fired reminder and records delivery so the
/// rule evaluator does not re-alert.
@MainActor
final class NotificationService {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// Ask for notification authorization. Explain why in the UI first.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Deliver one local alert for a fired reminder.
    func deliver(reminderID: UUID, title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // Fire immediately; the trigger decision has already been made upstream.
        let request = UNNotificationRequest(
            identifier: reminderID.uuidString,
            content: content,
            trigger: nil
        )
        try? await center.add(request)
    }
}
