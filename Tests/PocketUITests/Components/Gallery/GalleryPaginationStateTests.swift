import XCTest

@testable import PocketUI

final class GalleryPaginationStateTests: XCTestCase {
    func testRequestsNextPageOnlyWhenLastItemAppears() {
        var state = GalleryPagination.State<String>()
        let itemIDs = ["first", "second"]

        XCTAssertFalse(
            state.recordAppearance(
                of: "first",
                itemIDs: itemIDs,
                canRequestNextPage: true
            )
        )
        XCTAssertTrue(
            state.recordAppearance(
                of: "second",
                itemIDs: itemIDs,
                canRequestNextPage: true
            )
        )
        XCTAssertFalse(
            state.recordAppearance(
                of: "second",
                itemIDs: itemIDs,
                canRequestNextPage: true
            )
        )
    }

    func testVisibleLastItemCanRequestNextPageWhenFetchingResumes() {
        var state = GalleryPagination.State<String>()
        let itemIDs = ["first", "second"]

        XCTAssertFalse(
            state.recordAppearance(
                of: "second",
                itemIDs: itemIDs,
                canRequestNextPage: false
            )
        )

        XCTAssertTrue(
            state.requestNextPageIfNeeded(
                itemIDs: itemIDs,
                canRequestNextPage: true
            )
        )
    }

    func testSyncVisibleItemsPrunesNoLongerVisibleItems() {
        var state = GalleryPagination.State<String>()

        XCTAssertTrue(
            state.recordAppearance(
                of: "second",
                itemIDs: ["first", "second"],
                canRequestNextPage: true
            )
        )

        state.syncVisibleItems(with: ["third"])

        XCTAssertFalse(
            state.requestNextPageIfNeeded(
                itemIDs: ["third"],
                canRequestNextPage: true
            )
        )
    }

    func testAppendingItemsWaitsForNewLastItemToAppear() {
        var state = GalleryPagination.State<String>()

        XCTAssertTrue(
            state.recordAppearance(
                of: "second",
                itemIDs: ["first", "second"],
                canRequestNextPage: true
            )
        )

        state.syncVisibleItems(with: ["first", "second", "third"])

        XCTAssertFalse(
            state.requestNextPageIfNeeded(
                itemIDs: ["first", "second", "third"],
                canRequestNextPage: true
            )
        )
        XCTAssertTrue(
            state.recordAppearance(
                of: "third",
                itemIDs: ["first", "second", "third"],
                canRequestNextPage: true
            )
        )
    }

    func testThresholdCanRequestNextPageBeforeLastItemAppears() {
        var state = GalleryPagination.State<String>()
        let itemIDs = ["first", "second", "third", "fourth"]

        XCTAssertTrue(
            state.recordAppearance(
                of: "third",
                itemIDs: itemIDs,
                canRequestNextPage: true,
                threshold: 2
            )
        )
        XCTAssertFalse(
            state.recordAppearance(
                of: "fourth",
                itemIDs: itemIDs,
                canRequestNextPage: true,
                threshold: 2
            )
        )
    }

    func testSyncVisibleItemsPreservesRequestedBoundaryForSameItems() {
        var state = GalleryPagination.State<String>()
        let itemIDs = ["first", "second"]

        XCTAssertTrue(
            state.recordAppearance(
                of: "second",
                itemIDs: itemIDs,
                canRequestNextPage: true
            )
        )

        state.syncVisibleItems(with: itemIDs)

        XCTAssertFalse(
            state.requestNextPageIfNeeded(
                itemIDs: itemIDs,
                canRequestNextPage: true
            )
        )
    }

    func testAllowRetryForCurrentItemsRequestsSameVisibleBoundaryAgain() {
        var state = GalleryPagination.State<String>()
        let itemIDs = ["first", "second"]

        XCTAssertTrue(
            state.recordAppearance(
                of: "second",
                itemIDs: itemIDs,
                canRequestNextPage: true
            )
        )

        state.allowRetryForCurrentItems()

        XCTAssertTrue(
            state.requestNextPageIfNeeded(
                itemIDs: itemIDs,
                canRequestNextPage: true
            )
        )
    }

    func testNewBoundaryCanRequestWhenVisibleItemIsWithinThreshold() {
        var state = GalleryPagination.State<String>()

        XCTAssertTrue(
            state.recordAppearance(
                of: "second",
                itemIDs: ["first", "second"],
                canRequestNextPage: true
            )
        )

        state.syncVisibleItems(with: ["first", "second", "third"])

        XCTAssertTrue(
            state.requestNextPageIfNeeded(
                itemIDs: ["first", "second", "third"],
                canRequestNextPage: true,
                threshold: 2
            )
        )
    }
}
