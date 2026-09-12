import XCTest
import SwiftData
@testable import VisionRecall

@MainActor
final class MemoryStoreTests: XCTestCase {
    // A single in-memory container shared across tests. Creating a new ModelContainer
    // per test method crashes SwiftData when the same models are registered repeatedly
    // in one process, so we reuse one container and wipe it between tests.
    private static let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: MemoryKey.self, Reminder.self, configurations: config)
    }()

    private var store: MemoryStore!

    override func setUpWithError() throws {
        let context = Self.container.mainContext
        try context.delete(model: MemoryKey.self)
        try context.delete(model: Reminder.self)
        store = MemoryStore(context: context)
    }

    func testAddedMemoryKeyIsPersisted() {
        store.addMemoryKey(name: "Front door", label: "door")
        XCTAssertEqual(store.memoryKeys().count, 1)
        XCTAssertEqual(store.memoryKeys().first?.label, "door")
    }

    func testMatchedKeyIDsFindsKeyByLabelAndAlias() {
        let boxes = store.addMemoryKey(name: "Boxes", label: "boxes", aliases: ["carton"])
        store.addMemoryKey(name: "Front door", label: "door")

        XCTAssertEqual(store.matchedKeyIDs(for: ["carton", "wall"]), [boxes.id])
        XCTAssertTrue(store.matchedKeyIDs(for: ["window"]).isEmpty)
    }

    func testActiveOnlyExcludesFiredReminders() {
        store.addReminder(Reminder(text: "armed"))
        store.addReminder(Reminder(text: "done", hasFired: true))

        XCTAssertEqual(store.reminders().count, 2)
        XCTAssertEqual(store.reminders(activeOnly: true).map(\.text), ["armed"])
    }

    func testReminderProjectsTimeWindowIntoRule() {
        let reminder = Reminder(text: "t", startHour: 7, endHour: 10)
        XCTAssertEqual(reminder.rule.allowedHourRange, 7...10)

        let noWindow = Reminder(text: "t")
        XCTAssertNil(noWindow.rule.allowedHourRange)
    }
}
