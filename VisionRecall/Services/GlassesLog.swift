import Foundation
import os

/// Diagnostic logging for the glasses flow.
///
/// Writes to both the unified log (visible in Console.app) and stdout, so the output
/// also shows up in Xcode's console and in
/// `xcrun devicectl device process launch --console`.
enum GlassesLog {
    private static let logger = Logger(
        subsystem: "com.visionrecall.VisionRecall",
        category: "Glasses"
    )

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
        print("[VisionRecall] \(message)")
    }

    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
        print("[VisionRecall][ERROR] \(message)")
    }
}
