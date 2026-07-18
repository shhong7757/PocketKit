import Foundation

/// 갤러리의 다음 페이지 요청 설정입니다.
public struct GalleryPagination {
    /// 다음 페이지가 남아 있는지 여부입니다.
    public let hasNextPage: Bool

    /// 다음 페이지를 불러오는 중인지 여부입니다.
    public let isFetchingNextPage: Bool

    /// 항목이 viewport에 이 비율만큼 보였을 때 다음 페이지를 미리 요청할지 정합니다.
    public let visibilityThreshold: Double

    private let fetchNextPageAction: () -> Void

    /// 다음 페이지 요청을 사용하지 않습니다.
    public static var disabled: GalleryPagination {
        GalleryPagination(
            hasNextPage: false,
            isFetchingNextPage: false,
            visibilityThreshold: 0.2,
            fetchNextPage: {}
        )
    }

    /// 다음 페이지 요청 설정을 만듭니다.
    public init(
        hasNextPage: Bool = false,
        isFetchingNextPage: Bool = false,
        visibilityThreshold: Double = 0.2,
        fetchNextPage: @escaping () -> Void = {}
    ) {
        self.hasNextPage = hasNextPage
        self.isFetchingNextPage = isFetchingNextPage
        self.visibilityThreshold = visibilityThreshold
        self.fetchNextPageAction = fetchNextPage
    }

    internal var resolvedVisibilityThreshold: Double {
        min(max(visibilityThreshold, 0), 1)
    }

    internal func requestNextPage() {
        guard hasNextPage, !isFetchingNextPage else { return }

        fetchNextPageAction()
    }
}

extension GalleryPagination {
    struct State<ID: Hashable> {
        private var visibleItemIDs: Set<ID> = []
        private var lastRequestedPageBoundary: GalleryPaginationPageBoundary<ID>?

        mutating func recordVisibleItems(
            _ visibleIDs: [ID],
            itemIDs: [ID],
            canRequestNextPage: Bool
        ) -> Bool {
            visibleItemIDs = Set(visibleIDs)

            if let lastItemID = itemIDs.last,
               !visibleItemIDs.contains(lastItemID) {
                lastRequestedPageBoundary = nil
            }

            return requestNextPageIfNeeded(
                itemIDs: itemIDs,
                canRequestNextPage: canRequestNextPage
            )
        }

        mutating func syncVisibleItems(with itemIDs: [ID]) {
            visibleItemIDs = visibleItemIDs.intersection(itemIDs)
        }

        mutating func allowRetryForCurrentItems() {
            lastRequestedPageBoundary = nil
        }

        mutating func requestNextPageIfNeeded(
            itemIDs: [ID],
            canRequestNextPage: Bool
        ) -> Bool {
            guard let lastItemID = itemIDs.last,
                  visibleItemIDs.contains(lastItemID) else {
                return false
            }

            guard canRequestNextPage else { return false }

            return markPageBoundaryRequestedIfNeeded(itemIDs: itemIDs)
        }

        private mutating func markPageBoundaryRequestedIfNeeded(
            itemIDs: [ID]
        ) -> Bool {
            guard
                let pageBoundary = GalleryPaginationPageBoundary(
                    itemIDs: itemIDs
                )
            else {
                return false
            }

            guard lastRequestedPageBoundary != pageBoundary else {
                return false
            }

            lastRequestedPageBoundary = pageBoundary
            return true
        }

    }
}

private struct GalleryPaginationPageBoundary<ID: Equatable>: Equatable {
    let lastID: ID
    let itemCount: Int

    init?(itemIDs: [ID]) {
        guard let lastID = itemIDs.last else { return nil }

        self.lastID = lastID
        self.itemCount = itemIDs.count
    }
}
