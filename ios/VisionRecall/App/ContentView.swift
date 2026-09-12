import SwiftUI
import VisionRecallMemory

struct ContentView: View {
    let captureStore: (any CaptureStoring)?

    var body: some View {
        TabView {
            HomeView(captureStore: captureStore)
                .tabItem { Label("Home", systemImage: "house") }
            RemindersView()
                .tabItem { Label("Reminders", systemImage: "bell") }
            MemoryKeysView()
                .tabItem { Label("Memory Keys", systemImage: "key") }
            LiveCaptureView()
                .tabItem { Label("Live", systemImage: "eye") }
        }
    }
}

#Preview {
    ContentView(captureStore: nil)
        .environment(GlassesController())
        .modelContainer(for: [MemoryKey.self, Reminder.self], inMemory: true)
}
