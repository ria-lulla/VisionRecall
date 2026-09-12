import Foundation

/// App-lifecycle hooks for the Meta DAT SDK. No-ops on Simulator; on device they call
/// through to `Wearables`.
enum GlassesRuntime {

    /// Call once at app launch.
    @MainActor
    static func configure() {
        #if canImport(MWDATCore) && !targetEnvironment(simulator)
        do {
            try Wearables.configure()
        } catch {
            assertionFailure("Failed to configure Wearables SDK: \(error)")
        }
        #endif
    }

    /// Handle the Meta AI app's registration callback (custom URL scheme).
    @MainActor
    static func handleCallback(_ url: URL) {
        #if canImport(MWDATCore) && !targetEnvironment(simulator)
        Task { _ = try? await Wearables.shared.handleUrl(url) }
        #endif
    }
}

#if canImport(MWDATCore) && !targetEnvironment(simulator)
import MWDATCore
#endif
