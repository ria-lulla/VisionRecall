import SwiftUI
import SwiftData

@main
struct VisionRecallApp: App {
    let container: ModelContainer
    @State private var engine: ContextEngine
    @State private var glasses = GlassesController()

    init() {
        // Must run before anything touches Wearables.
        GlassesRuntime.configure()

        let container: ModelContainer
        do {
            container = try ModelContainer(for: MemoryKey.self, Reminder.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        self.container = container

        let store = MemoryStore(context: container.mainContext)
        _engine = State(initialValue: ContextEngine(
            capture: MockCaptureService(),
            vision: DefaultVisionService(),
            store: store,
            notifier: NotificationService(),
            location: CoreLocationContextProvider()
        ))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(engine)
                .environment(glasses)
                .task {
                    glasses.activate()
                }
                .onOpenURL { url in
                    GlassesRuntime.handleCallback(url)
                }
        }
        .modelContainer(container)
    }
}
