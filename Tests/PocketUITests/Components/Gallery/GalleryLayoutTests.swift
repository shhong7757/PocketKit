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

    func testCompactLayoutUsesReducedVerticalPadding() {
        let layout = GalleryLayout.compact

        XCTAssertEqual(layout.gap, .space1)
        XCTAssertEqual(layout.minimumColumnWidth, 110)
        XCTAssertEqual(layout.maximumColumnWidth, 170)
        XCTAssertEqual(
            layout.contentPadding,
            GalleryLayout.Insets(
                top: 0,
                leading: .space1,
                bottom: 0,
                trailing: .space1
            ))
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
