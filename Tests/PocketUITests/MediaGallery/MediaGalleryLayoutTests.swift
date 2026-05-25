import XCTest

@testable import PocketUI

final class MediaGalleryLayoutTests: XCTestCase {
    func testLayoutClampsInvalidValues() {
        let layout = MediaGalleryLayout(
            spacing: -4,
            minimumColumnWidth: -10,
            maximumColumnWidth: 0,
            cellAspectRatio: 0
        )

        XCTAssertEqual(layout.resolvedSpacing, 0)
        XCTAssertEqual(layout.resolvedMinimumColumnWidth, 1)
        XCTAssertEqual(layout.resolvedMaximumColumnWidth, 1)
        XCTAssertEqual(layout.resolvedCellAspectRatio, 1)
    }

    func testMaximumColumnWidthDoesNotFallBelowMinimumColumnWidth() {
        let layout = MediaGalleryLayout(
            minimumColumnWidth: 160,
            maximumColumnWidth: 80
        )

        XCTAssertEqual(layout.resolvedMinimumColumnWidth, 160)
        XCTAssertEqual(layout.resolvedMaximumColumnWidth, 160)
    }
}
