import SwiftUI
import SwiftData

/// Demo surface for the mock-device flow: script what the glasses see, sample a frame,
/// and watch the rule evaluator consume the phone's derived location context.
struct LiveCaptureView: View {
    @Environment(\.modelContext) private var context
    @Environment(ContextEngine.self) private var engine

    @State private var scriptedLabelsText = "door, boxes"

    var body: some View {
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

                locationSection

                Section("Reminder notifications") {
                    Text("Allow notifications to receive a reminder when the required visual and location signals match.")
                        .foregroundStyle(.secondary)
                    Button("Enable notifications") {
                        Task { await NotificationService().requestAuthorization() }
                    }
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

    @ViewBuilder
    private var locationSection: some View {
        Section("Home location") {
            if engine.homeLocation == nil {
                Text("Set your current location as home to enable home and departure signals.")
                    .foregroundStyle(.secondary)
                Button("Enable location") {
                    engine.requestLocationAuthorization()
                }
                Button("Set current location as home") {
                    engine.setHomeToCurrentLocation()
                }
                .disabled(engine.locationAuthorizationStatus != .authorizedWhenInUse && engine.locationAuthorizationStatus != .authorizedAlways)
            } else {
                LabeledContent("Status", value: engine.isAtHome ? "At home" : "Away")
                if engine.isDepartingContext {
                    Label("Home exit detected", systemImage: "figure.walk.departure")
                        .foregroundStyle(.orange)
                }
                Button("Clear home location", role: .destructive) {
                    engine.clearHomeLocation()
                }
            }
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
