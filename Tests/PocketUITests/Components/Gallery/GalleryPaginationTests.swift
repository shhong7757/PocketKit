import XCTest

@testable import PocketUI

final class GalleryPaginationTests: XCTestCase {
    func testPaginationResolvesVisibilityThresholdToValidRange() {
        let pagination = GalleryPagination(visibilityThreshold: 1.5)

        XCTAssertEqual(pagination.resolvedVisibilityThreshold, 1)

        let lowerBoundPagination = GalleryPagination(visibilityThreshold: -0.5)

        XCTAssertEqual(lowerBoundPagination.resolvedVisibilityThreshold, 0)
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
