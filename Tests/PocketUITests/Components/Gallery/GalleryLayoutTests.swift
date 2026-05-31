import XCTest

@testable import PocketUI

final class GalleryLayoutTests: XCTestCase {
    func testLayoutResolvesInvalidValuesToSafeGridInputs() {
        let layout = GalleryLayout(
            spacing: -4,
            minimumColumnWidth: -10,
            maximumColumnWidth: 0,
            cellAspectRatio: 0,
            contentInsets: GalleryLayout.Insets(
                top: -1,
                leading: -2,
                bottom: -3,
                trailing: -4
            )
        )

        XCTAssertEqual(layout.resolvedSpacing, 0)
        XCTAssertEqual(layout.resolvedMinimumColumnWidth, 1)
        XCTAssertEqual(layout.resolvedMaximumColumnWidth, 1)
        XCTAssertEqual(layout.resolvedCellAspectRatio, 1)
        XCTAssertEqual(layout.resolvedContentInsets, .zero)
    }

    func testLayoutKeepsMaximumColumnWidthAtLeastMinimumColumnWidth() {
        let layout = GalleryLayout(
            minimumColumnWidth: 160,
            maximumColumnWidth: 80
        )

        XCTAssertEqual(layout.resolvedMinimumColumnWidth, 160)
        XCTAssertEqual(layout.resolvedMaximumColumnWidth, 160)
    }
}
