import XCTest

@testable import PocketUI

final class GalleryPaginationTests: XCTestCase {
    func testPaginationResolvesInvalidThresholdToMinimumPrefetchWindow() {
        let pagination = GalleryPagination(threshold: 0)

        XCTAssertEqual(pagination.resolvedThreshold, 1)
    }

    func testPaginationRequestsNextPageOnlyWhenAvailable() {
        var requestCount = 0

        GalleryPagination(
            hasNextPage: true,
            fetchNextPage: {
                requestCount += 1
            }
        ).requestNextPage()

        XCTAssertEqual(requestCount, 1)

        GalleryPagination(
            hasNextPage: false,
            fetchNextPage: {
                requestCount += 1
            }
        ).requestNextPage()

        GalleryPagination(
            hasNextPage: true,
            isFetchingNextPage: true,
            fetchNextPage: {
                requestCount += 1
            }
        ).requestNextPage()

        XCTAssertEqual(requestCount, 1)
    }
}
