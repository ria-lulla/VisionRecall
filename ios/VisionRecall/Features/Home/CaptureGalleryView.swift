import SwiftUI
import UIKit
import VisionRecallMemory

@MainActor
final class CaptureGalleryViewModel: ObservableObject {
    @Published private(set) var captures: [Capture] = []
    @Published private(set) var imageData: [UUID: Data] = [:]

    private let captureStore: any CaptureStoring

    init(captureStore: any CaptureStoring) {
        self.captureStore = captureStore
    }

    func load() async {
        do {
            let captures = try await captureStore.recentCaptures()
            var data: [UUID: Data] = [:]
            for capture in captures {
                data[capture.id] = try await captureStore.imageData(for: capture)
            }
            self.captures = captures
            imageData = data
        } catch {
            captures = []
            imageData = [:]
        }
    }

    func clear() async {
        do {
            try await captureStore.clear()
            captures = []
            imageData = [:]
        } catch {
            // Keeping the current gallery is safer than implying captures were deleted.
        }
    }
}

struct CaptureGalleryView: View {
    @StateObject private var viewModel: CaptureGalleryViewModel

    init(captureStore: any CaptureStoring) {
        _viewModel = StateObject(wrappedValue: CaptureGalleryViewModel(captureStore: captureStore))
    }

    var body: some View {
        Section("Recent captures") {
            if viewModel.captures.isEmpty {
                ContentUnavailableView("No recent captures", systemImage: "camera")
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(viewModel.captures) { capture in
                            if let data = viewModel.imageData[capture.id], let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 112, height: 112)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .accessibilityLabel("Capture from \(capture.capturedAt.formatted())")
                            }
                        }
                    }
                }

                Button("Clear captures", role: .destructive) {
                    Task { await viewModel.clear() }
                }
            }
        }
        .task { await viewModel.load() }
    }
}
