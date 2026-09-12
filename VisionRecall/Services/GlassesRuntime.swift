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
            GlassesLog.info("Wearables.configure() succeeded")
        } catch {
            GlassesLog.error("Wearables.configure() failed: \(error)")
        }
        #else
        GlassesLog.info("Simulator build: DAT SDK not active")
        #endif
    }

    /// Handle the Meta AI app's registration callback (custom URL scheme).
    @MainActor
    static func handleCallback(_ url: URL) {
        #if canImport(MWDATCore) && !targetEnvironment(simulator)
        GlassesLog.info("handleCallback url=\(url.absoluteString)")
        Task {
            do {
                let handled = try await Wearables.shared.handleUrl(url)
                GlassesLog.info("handleUrl handled=\(handled)")
            } catch {
                GlassesLog.error("handleUrl failed: \(error)")
            }
        }
        #endif
    }
}

#if canImport(MWDATCore) && !targetEnvironment(simulator)
import MWDATCore
#endif
