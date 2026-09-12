import XCTest
@testable import VisionRecall

@MainActor
final class LocationContextProviderTests: XCTestCase {
    func testMockProviderMakesExitADepartureContext() {
        let provider = MockLocationContextProvider(isAtHome: true)

        provider.setContext(isAtHome: false, isDepartingContext: true)

        XCTAssertFalse(provider.isAtHome)
        XCTAssertTrue(provider.isDepartingContext)
    }

    func testMockProviderMakesHomeEntryClearDepartureContext() {
        let provider = MockLocationContextProvider(isAtHome: false, isDepartingContext: true)

        provider.setContext(isAtHome: true, isDepartingContext: false)

        XCTAssertTrue(provider.isAtHome)
        XCTAssertFalse(provider.isDepartingContext)
    }
}
