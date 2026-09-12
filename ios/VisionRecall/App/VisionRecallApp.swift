import SwiftUI
import SwiftData
import VisionRecallMemory

@main
struct VisionRecallApp: App {
    let container: ModelContainer
    let captureStore: (any CaptureStoring)?
    @State private var engine: ContextEngine
    @State private var glasses: GlassesController

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

        // Recent captures live in a bounded, backup-excluded cache. If it can't be
        // created the app still works, just without a persistent gallery.
        let captureStore = try? CaptureStore()
        self.captureStore = captureStore
        _glasses = State(initialValue: GlassesController(captureStore: captureStore))

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
            ContentView(captureStore: captureStore)
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
