import Foundation

/// 갤러리의 다음 페이지 요청 설정입니다.
public struct GalleryPagination {
    /// 다음 페이지가 남아 있는지 여부입니다.
    public let hasNextPage: Bool

    /// 다음 페이지를 불러오는 중인지 여부입니다.
    public let isFetchingNextPage: Bool

    /// 마지막 몇 개 항목 중 하나가 보였을 때 다음 페이지를 미리 요청할지 정합니다.
    public let threshold: Int

    private let fetchNextPageAction: () -> Void

    /// 다음 페이지 요청을 사용하지 않습니다.
    public static var disabled: GalleryPagination {
        GalleryPagination(
            hasNextPage: false,
            isFetchingNextPage: false,
            threshold: 1,
            fetchNextPage: {}
        )
    }

    /// 다음 페이지 요청 설정을 만듭니다.
    public init(
        hasNextPage: Bool = false,
        isFetchingNextPage: Bool = false,
        threshold: Int = 1,
        fetchNextPage: @escaping () -> Void = {}
    ) {
        self.hasNextPage = hasNextPage
        self.isFetchingNextPage = isFetchingNextPage
        self.threshold = threshold
        self.fetchNextPageAction = fetchNextPage
    }

    internal var resolvedThreshold: Int {
        max(1, threshold)
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

        mutating func recordAppearance(
            of id: ID,
            itemIDs: [ID],
            canRequestNextPage: Bool,
            threshold: Int = 1
        ) -> Bool {
            visibleItemIDs.insert(id)
            return requestNextPageIfNeeded(
                for: id,
                itemIDs: itemIDs,
                canRequestNextPage: canRequestNextPage,
                threshold: threshold
            )
        }

        mutating func recordDisappearance(of id: ID) {
            visibleItemIDs.remove(id)
        }

        mutating func syncVisibleItems(with itemIDs: [ID]) {
            visibleItemIDs = visibleItemIDs.intersection(itemIDs)
        }

        mutating func allowRetryForCurrentItems() {
            lastRequestedPageBoundary = nil
        }

        mutating func requestNextPageIfNeeded(
            itemIDs: [ID],
            canRequestNextPage: Bool,
            threshold: Int = 1
        ) -> Bool {
            guard visibleItemIDs.contains(where: { id in
                isPrefetchTrigger(
                    id,
                    itemIDs: itemIDs,
                    threshold: threshold
                )
            })
            else {
                return false
            }

            guard canRequestNextPage else { return false }

            return markPageBoundaryRequestedIfNeeded(itemIDs: itemIDs)
        }

        private mutating func requestNextPageIfNeeded(
            for visibleID: ID,
            itemIDs: [ID],
            canRequestNextPage: Bool,
            threshold: Int
        ) -> Bool {
            guard canRequestNextPage else { return false }
            guard isPrefetchTrigger(
                visibleID,
                itemIDs: itemIDs,
                threshold: threshold
            ) else {
                return false
            }

            return markPageBoundaryRequestedIfNeeded(itemIDs: itemIDs)
        }

        private mutating func markPageBoundaryRequestedIfNeeded(
            itemIDs: [ID]
        ) -> Bool {
            guard let pageBoundary = GalleryPaginationPageBoundary(
                itemIDs: itemIDs
            ) else {
                return false
            }

            guard lastRequestedPageBoundary != pageBoundary else {
                return false
            }

            lastRequestedPageBoundary = pageBoundary
            return true
        }

        private func isPrefetchTrigger(
            _ id: ID,
            itemIDs: [ID],
            threshold: Int
        ) -> Bool {
            return itemIDs.suffix(threshold).contains(id)
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
