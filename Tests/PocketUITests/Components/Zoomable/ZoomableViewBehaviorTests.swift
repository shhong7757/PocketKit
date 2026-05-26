import XCTest

@testable import PocketUI

final class ZoomableViewBehaviorTests: XCTestCase {
    func testMaximumScaleCannotShrinkBelowOriginalScale() {
        let behavior = ZoomableViewBehavior(
            maximumScale: 0,
            doubleTapScale: 4
        )

        XCTAssertEqual(behavior.resolvedMaximumScale, 1)
        XCTAssertEqual(behavior.resolvedDoubleTapScale, 1)
    }

    func testDoubleTapScaleIsClampedBetweenOriginalAndMaximumScale() {
        let tooSmall = ZoomableViewBehavior(
            maximumScale: 4,
            doubleTapScale: 0.5
        )
        let tooLarge = ZoomableViewBehavior(
            maximumScale: 4,
            doubleTapScale: 8
        )

        XCTAssertEqual(tooSmall.resolvedDoubleTapScale, 1)
        XCTAssertEqual(tooLarge.resolvedDoubleTapScale, 4)
    }

    func testMinimumTransientScaleIsClampedToUsablePinchRange() {
        let tooSmall = ZoomableViewBehavior(minimumTransientScale: -1)
        let tooLarge = ZoomableViewBehavior(minimumTransientScale: 2)

        XCTAssertEqual(tooSmall.resolvedMinimumTransientScale, 0.1)
        XCTAssertEqual(tooLarge.resolvedMinimumTransientScale, 1)
    }

    func testValidScaleConfigurationIsPreserved() {
        let behavior = ZoomableViewBehavior(
            maximumScale: 6,
            doubleTapScale: 3,
            minimumTransientScale: 0.75
        )

        XCTAssertEqual(behavior.resolvedMaximumScale, 6)
        XCTAssertEqual(behavior.resolvedDoubleTapScale, 3)
        XCTAssertEqual(behavior.resolvedMinimumTransientScale, 0.75)
    }
}
