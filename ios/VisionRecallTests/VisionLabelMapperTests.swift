import XCTest
import UIKit
@testable import VisionRecall

final class VisionLabelMapperTests: XCTestCase {
    func testBundledRepresentativeImagesCanBeClassifiedOnDevice() throws {
        for imageName in ["front-door", "cardboard-boxes"] {
            let fileExtension = imageName == "front-door" ? "jpg" : "png"
            let url = try XCTUnwrap(
                Bundle(for: Self.self).url(forResource: imageName, withExtension: fileExtension),
                "Missing bundled test image: \(imageName)"
            )
            let image = try XCTUnwrap(
                UIImage(contentsOfFile: url.path),
                "Missing bundled test image: \(imageName)"
            )
            XCTAssertNotNil(image.cgImage, "Test image must be usable by Vision: \(imageName)")
        }

        #if targetEnvironment(simulator)
        throw XCTSkip("VNClassifyImageRequest cannot create its classifier context in iOS Simulator; run this assertion on a physical iPhone or paired glasses.")
        #else
        let service = DefaultVisionService(minimumConfidence: 0.05, maxLabels: 12)
        for imageName in ["front-door", "cardboard-boxes"] {
            let fileExtension = imageName == "front-door" ? "jpg" : "png"
            let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: imageName, withExtension: fileExtension))
            let image = try XCTUnwrap(UIImage(contentsOfFile: url.path))
            let labels = service.labels(for: CameraFrame(image: image))

            XCTAssertFalse(labels.isEmpty, "Vision returned no labels for \(imageName)")
        }
        #endif
    }

    func testCardboardBoxIdentifierMatchesBoxesMemoryKey() {
        let key = MemoryKey(name: "Moving boxes", label: "boxes")
        let labels = VisionLabelMapper.labels(for: ["cardboard box"], limit: 6)

        XCTAssertTrue(key.matches(labels: labels))
    }

    func testCartonIdentifierMatchesBoxMemoryKey() {
        let key = MemoryKey(name: "Packages", label: "box")

        XCTAssertTrue(key.matches(labels: ["carton"]))
    }

    func testDoorwayIdentifierMatchesDoorMemoryKey() {
        let key = MemoryKey(name: "Front door", label: "door")

        XCTAssertTrue(key.matches(labels: ["doorway"]))
    }

    func testPunctuationAndCaseDoNotAffectAliasMatching() {
        let key = MemoryKey(name: "Front door", label: "door", aliases: ["front-entry"])

        XCTAssertTrue(key.matches(labels: ["Front Entry"] ))
    }

    func testMapperHonorsLabelLimit() {
        XCTAssertEqual(VisionLabelMapper.labels(for: ["cardboard box"], limit: 2), ["cardboard box", "cardboard"])
    }
}
