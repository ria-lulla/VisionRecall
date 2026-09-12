import Foundation
import SwiftData

/// Thin persistence facade over SwiftData for memory keys and reminders, plus the
/// key-matching helper used to build a `ContextSnapshot`.
@MainActor
final class MemoryStore {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: Memory keys

    @discardableResult
    func addMemoryKey(name: String, label: String, aliases: [String] = []) -> MemoryKey {
        let key = MemoryKey(name: name, label: label, aliases: aliases)
        context.insert(key)
        return key
    }

    func memoryKeys() -> [MemoryKey] {
        (try? context.fetch(FetchDescriptor<MemoryKey>(
            sortBy: [SortDescriptor(\.createdAt)]
        ))) ?? []
    }

    // MARK: Reminders

    @discardableResult
    func addReminder(_ reminder: Reminder) -> Reminder {
        context.insert(reminder)
        return reminder
    }

    func reminders(activeOnly: Bool = false) -> [Reminder] {
        let all = (try? context.fetch(FetchDescriptor<Reminder>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        ))) ?? []
        return activeOnly ? all.filter { $0.isActive && !$0.hasFired } : all
    }

    func delete(_ object: any PersistentModel) {
        context.delete(object)
    }

    // MARK: Matching

    /// Returns the IDs of memory keys matched by the given vision labels.
    func matchedKeyIDs(for labels: [String]) -> Set<UUID> {
        Set(memoryKeys().filter { $0.matches(labels: labels) }.map(\.id))
    }
}
