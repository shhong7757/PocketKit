import XCTest

@testable import PocketUI

final class MediaDetailSelectionExtensionTests: XCTestCase {
    private let items = [
        TestMediaItem(id: "first", title: "First"),
        TestMediaItem(id: "second", title: "Second"),
    ]

    func testNilSelectionResolvesToFirstItem() {
        XCTAssertEqual(
            items.mediaGalleryResolvedSelection(nil),
            items[0]
        )
    }

    func testInvalidSelectionResolvesToFirstItem() {
        let missingSelection = TestMediaItem(id: "missing")

        XCTAssertEqual(
            items.mediaGalleryResolvedSelection(missingSelection),
            items[0]
        )
    }

    func testStaleSelectionResolvesToCanonicalItemFromItems() {
        let staleSelection = TestMediaItem(
            id: "second",
            title: "Old title"
        )

        XCTAssertEqual(
            items.mediaGalleryResolvedSelection(staleSelection),
            items[1]
        )
    }

    func testEmptyItemsResolveToNil() {
        XCTAssertNil(
            [TestMediaItem]().mediaGalleryResolvedSelection(items[0])
        )
    }

    func testIndexUsesResolvedSelection() {
        let staleSelection = TestMediaItem(
            id: "second",
            title: "Old title"
        )

        XCTAssertEqual(
            items.mediaGalleryResolvedSelectionIndex(of: staleSelection),
            1
        )
        XCTAssertNil(
            [TestMediaItem]().mediaGalleryResolvedSelectionIndex(of: nil)
        )
    }
}

private struct TestMediaItem: Equatable, Identifiable {
    let id: String
    var title: String?
}
