import SwiftUI
import SwiftData

@main
struct VisionRecallApp: App {
    let container: ModelContainer
    @State private var engine: ContextEngine
    @State private var glasses = GlassesController()

    init() {
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
            notifier: NotificationService()
        ))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(engine)
                .environment(glasses)
                .task {
                    GlassesRuntime.configure()
                    await NotificationService().requestAuthorization()
                }
                .onOpenURL { url in
                    GlassesRuntime.handleCallback(url)
                }
        }
        .modelContainer(container)
    }
}
