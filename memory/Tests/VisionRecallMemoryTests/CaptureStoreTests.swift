import Foundation
import XCTest
@testable import VisionRecallMemory

final class CaptureStoreTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testCaptureSurvivesStoreRelaunch() async throws {
        let store = try CaptureStore(directory: directory)
        let capture = try await store.save(imageData: Data([0x01]), capturedAt: Date())

        let relaunchedStore = try CaptureStore(directory: directory)
        let captures = try await relaunchedStore.recentCaptures()

        XCTAssertEqual(captures, [capture])
        let persistedData = try await relaunchedStore.imageData(for: capture)
        XCTAssertEqual(persistedData, Data([0x01]))
    }

    func testPrunesCapturesOutsideTheRollingWindow() async throws {
        let now = Date()
        let store = try CaptureStore(
            directory: directory,
            retentionPolicy: CaptureRetentionPolicy(maximumCount: 3, maximumAge: 60)
        )
        _ = try await store.save(imageData: Data([0x01]), capturedAt: now.addingTimeInterval(-61))
        let recent = try await store.save(imageData: Data([0x02]), capturedAt: now)

        let captures = try await store.recentCaptures()

        XCTAssertEqual(captures, [recent])
    }

    func testPrunesOldestCapturesWhenMaximumCountIsReached() async throws {
        let base = Date()
        let store = try CaptureStore(
            directory: directory,
            retentionPolicy: CaptureRetentionPolicy(maximumCount: 2, maximumAge: 1_000)
        )
        let oldest = try await store.save(imageData: Data([0x01]), capturedAt: base)
        let middle = try await store.save(imageData: Data([0x02]), capturedAt: base.addingTimeInterval(1))
        let newest = try await store.save(imageData: Data([0x03]), capturedAt: base.addingTimeInterval(2))

        let captures = try await store.recentCaptures()
        XCTAssertEqual(captures, [newest, middle])
        await XCTAssertThrowsErrorAsync(try await store.imageData(for: oldest))
    }

    func testClearDeletesAllPersistedCaptures() async throws {
        let store = try CaptureStore(directory: directory)
        _ = try await store.save(imageData: Data([0x01]))
        let orphanURL = directory.appending(path: "interrupted-capture.jpg")
        try Data([0x02]).write(to: orphanURL)

        try await store.clear()

        let clearedCaptures = try await store.recentCaptures()
        XCTAssertTrue(clearedCaptures.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: orphanURL.path))
        let relaunchedStore = try CaptureStore(directory: directory)
        let relaunchedCaptures = try await relaunchedStore.recentCaptures()
        XCTAssertTrue(relaunchedCaptures.isEmpty)
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
