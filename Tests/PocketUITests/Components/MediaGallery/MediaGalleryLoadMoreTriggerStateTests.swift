import XCTest

@testable import PocketUI

final class MediaGalleryLoadMoreTriggerStateTests: XCTestCase {
    func testLoadMoreTriggersOnlyWhenLastItemAppears() {
        var state = LastItemLoadMoreTriggerState<String>()
        let itemIDs = ["first", "second"]

        XCTAssertFalse(
            state.itemDidAppear("first", itemIDs: itemIDs, canLoadMore: true)
        )
        XCTAssertTrue(
            state.itemDidAppear("second", itemIDs: itemIDs, canLoadMore: true)
        )
        XCTAssertFalse(
            state.itemDidAppear("second", itemIDs: itemIDs, canLoadMore: true)
        )
    }

    func testLoadMoreCanRetrySameItemsAfterResetWhenLastItemIsVisible() {
        var state = LastItemLoadMoreTriggerState<String>()
        let itemIDs = ["first", "second"]

        XCTAssertTrue(
            state.itemDidAppear("second", itemIDs: itemIDs, canLoadMore: true)
        )

        state.allowRetryForCurrentItems()

        XCTAssertTrue(
            state.triggerForVisibleLastItemIfNeeded(
                itemIDs: itemIDs,
                canLoadMore: true
            )
        )
    }

    func testRetryDoesNotTriggerWhenLastItemIsNotVisible() {
        var state = LastItemLoadMoreTriggerState<String>()
        let itemIDs = ["first", "second"]

        XCTAssertTrue(
            state.itemDidAppear("second", itemIDs: itemIDs, canLoadMore: true)
        )
        state.itemDidDisappear("second")
        state.allowRetryForCurrentItems()

        XCTAssertFalse(
            state.triggerForVisibleLastItemIfNeeded(
                itemIDs: itemIDs,
                canLoadMore: true
            )
        )
    }

    func testVisibleLastItemCanTriggerWhenLoadingResumes() {
        var state = LastItemLoadMoreTriggerState<String>()
        let itemIDs = ["first", "second"]

        XCTAssertFalse(
            state.itemDidAppear("second", itemIDs: itemIDs, canLoadMore: false)
        )
        state.allowRetryForCurrentItems()

        XCTAssertTrue(
            state.triggerForVisibleLastItemIfNeeded(
                itemIDs: itemIDs,
                canLoadMore: true
            )
        )
    }

    func testItemsDidChangePrunesNoLongerVisibleItems() {
        var state = LastItemLoadMoreTriggerState<String>()

        XCTAssertTrue(
            state.itemDidAppear(
                "second",
                itemIDs: ["first", "second"],
                canLoadMore: true
            )
        )

        state.itemsDidChange(to: ["third"])

        XCTAssertFalse(
            state.triggerForVisibleLastItemIfNeeded(
                itemIDs: ["third"],
                canLoadMore: true
            )
        )
    }

    func testAppendingItemsWaitsForNewLastItemToAppear() {
        var state = LastItemLoadMoreTriggerState<String>()

        XCTAssertTrue(
            state.itemDidAppear(
                "second",
                itemIDs: ["first", "second"],
                canLoadMore: true
            )
        )

        state.itemsDidChange(to: ["first", "second", "third"])

        XCTAssertFalse(
            state.triggerForVisibleLastItemIfNeeded(
                itemIDs: ["first", "second", "third"],
                canLoadMore: true
            )
        )
        XCTAssertTrue(
            state.itemDidAppear(
                "third",
                itemIDs: ["first", "second", "third"],
                canLoadMore: true
            )
        )
    }
}
