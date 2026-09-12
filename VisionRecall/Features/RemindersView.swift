import SwiftUI
import SwiftData

struct RemindersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Reminder.createdAt, order: .reverse) private var reminders: [Reminder]
    @State private var showingCreate = false

    var body: some View {
        NavigationStack {
            List {
                if reminders.isEmpty {
                    ContentUnavailableView(
                        "No reminders",
                        systemImage: "bell.slash",
                        description: Text("Create a reminder tied to a visual key, home, and a time window.")
                    )
                }
                ForEach(reminders) { reminder in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reminder.text).font(.headline)
                        HStack(spacing: 8) {
                            if reminder.hasFired {
                                Label("Delivered", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if reminder.isActive {
                                Label("Armed", systemImage: "dot.radiowaves.left.and.right")
                                    .foregroundStyle(.blue)
                            }
                            Text(triggerSummary(reminder))
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Reminders")
            .toolbar {
                Button {
                    showingCreate = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateReminderView()
            }
        }
    }

    private func triggerSummary(_ reminder: Reminder) -> String {
        var parts: [String] = []
        if !reminder.requiredKeyIDs.isEmpty { parts.append("visual") }
        if reminder.requiresHome { parts.append("home") }
        if reminder.requiresDepartingContext { parts.append("leaving") }
        if let start = reminder.startHour, let end = reminder.endHour {
            parts.append("\(start)–\(end)h")
        }
        return parts.isEmpty ? "no triggers" : parts.joined(separator: " · ")
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            context.delete(reminders[index])
        }
    }
}
