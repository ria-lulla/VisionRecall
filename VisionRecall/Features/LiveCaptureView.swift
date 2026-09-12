import SwiftUI
import SwiftData

/// Demo surface for the mock-device flow: script what the glasses "see", toggle phone
/// context, sample a frame, and watch the rule evaluator deliver a single alert.
struct LiveCaptureView: View {
    @Environment(\.modelContext) private var context
    @Environment(ContextEngine.self) private var engine

    @State private var scriptedLabelsText = "door, boxes"

    var body: some View {
        @Bindable var engine = engine
        NavigationStack {
            Form {
                Section("What the glasses see (mock)") {
                    TextField("labels, comma separated", text: $scriptedLabelsText)
                        .textInputAutocapitalization(.never)
                    Button("Capture frame now") {
                        engine.setScriptedLabels(parsedLabels)
                        engine.captureOnce()
                    }
                }

                Section("Phone context") {
                    Toggle("At home", isOn: $engine.isAtHome)
                    Toggle("Leaving / door context", isOn: $engine.isDepartingContext)
                }

                Section("Latest observation") {
                    LabeledContent("Labels", value: engine.latestLabels.joined(separator: ", "))
                    LabeledContent("Matched keys", value: engine.matchedKeyNames.joined(separator: ", "))
                    if let event = engine.lastEventDescription {
                        Text(event).foregroundStyle(.green)
                    }
                }

                Section("Demo") {
                    Button("Load \"boxes\" demo data", action: loadDemo)
                }
            }
            .navigationTitle("Live")
        }
    }

    private var parsedLabels: [String] {
        scriptedLabelsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
    }

    /// Seed the canonical first-demo rule from ARCHITECTURE.md.
    private func loadDemo() {
        let door = MemoryKey(name: "Front door", label: "door")
        let boxes = MemoryKey(name: "Boxes", label: "boxes", aliases: ["box", "carton"])
        context.insert(door)
        context.insert(boxes)
        context.insert(Reminder(
            text: "Take out the boxes when I leave home",
            requiredKeyIDs: [boxes.id],
            requiresHome: true,
            requiresDepartingContext: true,
            startHour: 7,
            endHour: 10,
            confidenceThreshold: 0.7
        ))
    }
}
