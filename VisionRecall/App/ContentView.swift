import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
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
    ContentView()
        .modelContainer(for: [MemoryKey.self, Reminder.self], inMemory: true)
}
