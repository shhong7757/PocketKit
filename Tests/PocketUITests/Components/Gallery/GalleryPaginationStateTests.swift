import XCTest

@testable import PocketUI

final class GalleryPaginationStateTests: XCTestCase {
    func testRequestsNextPageWhenLastVisibleItemIsReported() {
        var state = GalleryPagination.State<String>()
        let itemIDs = ["first", "second"]

        XCTAssertFalse(
            state.recordVisibleItems(
                ["first"],
                itemIDs: itemIDs,
                canRequestNextPage: true
            )
        )
        XCTAssertTrue(
            state.recordVisibleItems(
                ["second"],
                itemIDs: itemIDs,
                canRequestNextPage: true
            )
        )
        XCTAssertFalse(
            state.recordVisibleItems(
                ["second"],
                itemIDs: itemIDs,
                canRequestNextPage: true
            )
        )
    }

    func testSameVisibleBoundaryDoesNotRequestAgainAfterFetchingFinishes() {
        var state = GalleryPagination.State<String>()
        let itemIDs = ["first", "second"]

        XCTAssertTrue(
            state.recordVisibleItems(
                ["second"],
                itemIDs: itemIDs,
                canRequestNextPage: true
            )
        )
        XCTAssertFalse(
            state.requestNextPageIfNeeded(
                itemIDs: itemIDs,
                canRequestNextPage: true
            )
        )
    }

    func testBoundaryCanBeRequestedAgainAfterLeavingVisibility() {
        var state = GalleryPagination.State<String>()
        let itemIDs = ["first", "second"]

        XCTAssertTrue(
            state.recordVisibleItems(
                ["second"],
                itemIDs: itemIDs,
                canRequestNextPage: true
            )
        )
        XCTAssertFalse(
            state.recordVisibleItems(
                ["first"],
                itemIDs: itemIDs,
                canRequestNextPage: true
            )
        )
        XCTAssertTrue(
            state.recordVisibleItems(
                ["second"],
                itemIDs: itemIDs,
                canRequestNextPage: true
            )
        )
    }

    func testVisibleLastItemCanRequestNextPageWhenFetchingResumes() {
        var state = GalleryPagination.State<String>()
        let itemIDs = ["first", "second"]

        XCTAssertFalse(
            state.recordVisibleItems(
                ["second"],
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
            state.recordVisibleItems(
                ["second"],
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

    func testAppendingItemsWaitsForNewLastItemToBecomeVisible() {
        var state = GalleryPagination.State<String>()

        XCTAssertTrue(
            state.recordVisibleItems(
                ["second"],
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
            state.recordVisibleItems(
                ["third"],
                itemIDs: ["first", "second", "third"],
                canRequestNextPage: true
            )
        )
    }

    func testVisibleItemsReportedByVisibilityThresholdCanRequestNextPage() {
        var state = GalleryPagination.State<String>()
        let itemIDs = ["first", "second", "third", "fourth"]

        XCTAssertTrue(
            state.recordVisibleItems(
                ["third", "fourth"],
                itemIDs: itemIDs,
                canRequestNextPage: true
            )
        )
    }

    func testSyncVisibleItemsPreservesRequestedBoundaryForSameItems() {
        var state = GalleryPagination.State<String>()
        let itemIDs = ["first", "second"]

        XCTAssertTrue(
            state.recordVisibleItems(
                ["second"],
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
            state.recordVisibleItems(
                ["second"],
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

    func testNewBoundaryCanRequestWhenVisibleLastItemChanges() {
        var state = GalleryPagination.State<String>()

        XCTAssertTrue(
            state.recordVisibleItems(
                ["second"],
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
            state.recordVisibleItems(
                ["third"],
                itemIDs: ["first", "second", "third"],
                canRequestNextPage: true
            )
        )
    }
}
