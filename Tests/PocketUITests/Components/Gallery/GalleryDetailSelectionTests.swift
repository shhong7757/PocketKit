import XCTest

@testable import PocketUI

final class GalleryDetailSelectionTests: XCTestCase {
    func testResolvedPageIDPrefersValidPreferredID() {
        XCTAssertEqual(
            GalleryDetailSelection.resolvedPageID(
                preferredID: "third",
                currentID: "second",
                activeID: "first",
                sourceID: "first",
                itemIDs: ["first", "second", "third"]
            ),
            "third"
        )
    }

    func testResolvedPageIDFallsBackThroughCurrentActiveSourceAndFirstItem() {
        XCTAssertEqual(
            GalleryDetailSelection.resolvedPageID(
                preferredID: "missing",
                currentID: "second",
                activeID: "first",
                sourceID: "third",
                itemIDs: ["first", "second", "third"]
            ),
            "second"
        )

        XCTAssertEqual(
            GalleryDetailSelection.resolvedPageID(
                preferredID: nil,
                currentID: "missing",
                activeID: "first",
                sourceID: "third",
                itemIDs: ["first", "second", "third"]
            ),
            "first"
        )

        XCTAssertEqual(
            GalleryDetailSelection.resolvedPageID(
                preferredID: nil,
                currentID: nil,
                activeID: "missing",
                sourceID: "third",
                itemIDs: ["first", "second", "third"]
            ),
            "third"
        )

        XCTAssertEqual(
            GalleryDetailSelection.resolvedPageID(
                preferredID: nil,
                currentID: nil,
                activeID: nil,
                sourceID: "missing",
                itemIDs: ["first", "second", "third"]
            ),
            "first"
        )
    }

    func testResolvedPageIDReturnsNilForEmptyItems() {
        XCTAssertNil(
            GalleryDetailSelection<String>.resolvedPageID(
                preferredID: "first",
                currentID: nil,
                activeID: nil,
                sourceID: "first",
                itemIDs: []
            )
        )
    }
}
