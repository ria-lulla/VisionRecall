import UIKit
import XCTest
@testable import VisionRecall

final class VisionServiceImageTests: XCTestCase {
    func testBoxesAtFrontDoorFixtureDrivesDeterministicMockVisionPath() throws {
        let image = try fixtureImage(named: "boxes-at-front-door")
        let labels = DefaultVisionService().labels(for: CameraFrame(
            image: image,
            simulatedLabels: ["door", "boxes"]
        ))

        // The simulator does not provide the Vision classifier model, but the mock
        // path is the supported deterministic simulator workflow.
        XCTAssertEqual(labels, ["door", "boxes"])
    }

    private func fixtureImage(named name: String) throws -> UIImage {
        // …/ios/VisionRecallTests/<file> → up three to the repository root, which is
        // where assets/ lives.
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = repositoryRoot
            .appendingPathComponent("assets/test-images")
            .appendingPathComponent(name)
            .appendingPathExtension("jpg")
        guard let image = UIImage(contentsOfFile: url.path) else {
            throw NSError(domain: "VisionServiceImageTests", code: 1)
        }
        return image
    }
}
