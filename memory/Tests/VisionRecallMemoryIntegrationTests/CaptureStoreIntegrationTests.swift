import Foundation
import XCTest
@testable import VisionRecallMemory

final class CaptureStoreIntegrationTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testRelaunchPrunesExpiredCaptureAndRetainsRecentPhoto() async throws {
        let now = Date()
        let longLivedStore = try CaptureStore(
            directory: directory,
            retentionPolicy: CaptureRetentionPolicy(maximumCount: 10, maximumAge: 24 * 60 * 60)
        )
        let expiredCapture = try await longLivedStore.save(
            imageData: Data([0x01]),
            capturedAt: now.addingTimeInterval(-120)
        )
        let recentCapture = try await longLivedStore.save(imageData: Data([0x02]), capturedAt: now)

        let relaunchedStore = try CaptureStore(
            directory: directory,
            retentionPolicy: CaptureRetentionPolicy(maximumCount: 10, maximumAge: 60)
        )

        let captures = try await relaunchedStore.recentCaptures()
        XCTAssertEqual(captures, [recentCapture])
        let recentData = try await relaunchedStore.imageData(for: recentCapture)
        XCTAssertEqual(recentData, Data([0x02]))
        await XCTAssertThrowsErrorAsync(try await relaunchedStore.imageData(for: expiredCapture))
    }

    func testRelaunchAfterClearHasNoRecoverableCaptures() async throws {
        let store = try CaptureStore(directory: directory)
        _ = try await store.save(imageData: Data([0x01]))
        _ = try await store.save(imageData: Data([0x02]))

        try await store.clear()

        let relaunchedStore = try CaptureStore(directory: directory)
        let captures = try await relaunchedStore.recentCaptures()
        XCTAssertTrue(captures.isEmpty)
    }
}

private func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected an error", file: file, line: line)
    } catch {}
}
