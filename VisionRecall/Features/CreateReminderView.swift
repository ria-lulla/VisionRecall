import SwiftUI
import SwiftData

struct CreateReminderView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MemoryKey.createdAt) private var keys: [MemoryKey]

    @State private var text = ""
    @State private var selectedKeyIDs: Set<UUID> = []
    @State private var requiresHome = true
    @State private var requiresDeparting = true
    @State private var useTimeWindow = false
    @State private var startHour = 7
    @State private var endHour = 10
    @State private var threshold = 0.7

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder") {
                    TextField("e.g. Take out the boxes when I leave", text: $text, axis: .vertical)
                }

                Section("Visual keys") {
                    if keys.isEmpty {
                        Text("Register keys in the Memory Keys tab first.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(keys) { key in
                        Toggle(key.name, isOn: binding(for: key.id))
                    }
                }

                Section("Phone context") {
                    Toggle("Requires being at home", isOn: $requiresHome)
                    Toggle("Requires leaving/door context", isOn: $requiresDeparting)
                }

                Section("Time window") {
                    Toggle("Only within a time window", isOn: $useTimeWindow)
                    if useTimeWindow {
                        Stepper("From \(startHour):00", value: $startHour, in: 0...23)
                        Stepper("To \(endHour):00", value: $endHour, in: 0...23)
                    }
                }

                Section("Confidence threshold: \(Int(threshold * 100))%") {
                    Slider(value: $threshold, in: 0.3...1.0, step: 0.05)
                }
            }
            .navigationTitle("New Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(text.isEmpty)
                }
            }
        }
    }

    private func binding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { selectedKeyIDs.contains(id) },
            set: { isOn in
                if isOn { selectedKeyIDs.insert(id) } else { selectedKeyIDs.remove(id) }
            }
        )
    }

    private func save() {
        let reminder = Reminder(
            text: text,
            requiredKeyIDs: Array(selectedKeyIDs),
            requiresHome: requiresHome,
            requiresDepartingContext: requiresDeparting,
            startHour: useTimeWindow ? startHour : nil,
            endHour: useTimeWindow ? endHour : nil,
            confidenceThreshold: threshold
        )
        context.insert(reminder)
        dismiss()
    }
}
