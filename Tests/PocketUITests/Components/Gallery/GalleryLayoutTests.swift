import SwiftUI
import XCTest

@testable import PocketUI

final class GalleryLayoutTests: XCTestCase {
    func testLayoutResolvesInvalidValuesToSafeGridInputs() {
        let layout = GalleryLayout(
            gap: -4,
            minimumColumnWidth: -10,
            maximumColumnWidth: 0,
            cellAspectRatio: 0,
            contentPadding: EdgeInsets(
                top: -1,
                leading: -2,
                bottom: -3,
                trailing: -4
            )
        )

        XCTAssertEqual(layout.resolvedGap, 0)
        XCTAssertEqual(layout.resolvedMinimumColumnWidth, 1)
        XCTAssertEqual(layout.resolvedMaximumColumnWidth, 1)
        XCTAssertEqual(layout.resolvedCellAspectRatio, 1)
        XCTAssertEqual(layout.resolvedContentPadding, .zero)
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
