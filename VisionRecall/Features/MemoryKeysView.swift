import SwiftUI
import SwiftData

struct MemoryKeysView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MemoryKey.createdAt) private var keys: [MemoryKey]

    @State private var name = ""
    @State private var label = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Register a key") {
                    TextField("Name (e.g. Front door)", text: $name)
                    TextField("Vision label (e.g. door)", text: $label)
                        .textInputAutocapitalization(.never)
                    Button("Add memory key", action: addKey)
                        .disabled(name.isEmpty || label.isEmpty)
                }

                Section("Keys") {
                    if keys.isEmpty {
                        Text("No keys yet. Register a door or object above.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(keys) { key in
                        VStack(alignment: .leading) {
                            Text(key.name).font(.headline)
                            Text("matches: \(key.label)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Memory Keys")
        }
    }

    private func addKey() {
        context.insert(MemoryKey(name: name, label: label.lowercased()))
        name = ""
        label = ""
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            context.delete(keys[index])
        }
    }
}
