import SwiftUI

extension MediaGalleryView where DetailToolbar == MediaGalleryEmptyToolbarContent {
    /// 커스텀 그리드 콘텐츠와 빈 상태 콘텐츠를 사용하는 미디어 갤러리 흐름을 만듭니다.
    public init(
        items: [Item],
        selection: Binding<Item?>,
        contentDisplayMode: MediaGalleryContentDisplayMode = .fill,
        layout: MediaGalleryLayout = .standard,
        zoomBehavior: ZoomableViewBehavior = .init(),
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String = { "Media item \($0.id)" },
        canLoadMore: Bool = true,
        isLoadingMore: Bool = false,
        onLoadMore: @escaping () -> Void = {},
        @ViewBuilder thumbnailContent: @escaping (Item) -> Thumbnail,
        @ViewBuilder detailContent: @escaping (Item) -> DetailContent,
        @ViewBuilder overlayContent: @escaping (Item) -> OverlayContent,
        @ViewBuilder emptyStateContent: @escaping () -> EmptyContent
    ) {
        self.init(
            items: items,
            selection: selection,
            contentDisplayMode: contentDisplayMode,
            layout: layout,
            zoomBehavior: zoomBehavior,
            contentAspectRatio: contentAspectRatio,
            accessibilityLabel: accessibilityLabel,
            loadMoreBehavior: MediaGalleryLoadMoreBehavior(
                canLoadMore: canLoadMore,
                isLoadingMore: isLoadingMore,
                onLoadMore: onLoadMore
            ),
            thumbnailContent: thumbnailContent,
            detailContent: detailContent,
            overlayContent: overlayContent,
            emptyStateContent: emptyStateContent,
            detailToolbarContent: { _ in
                MediaGalleryEmptyToolbarContent()
            }
        )
    }
}

extension MediaGalleryView where OverlayContent == EmptyView {
    /// 그리드 오버레이 콘텐츠 없이 미디어 갤러리 흐름을 만듭니다.
    public init(
        items: [Item],
        selection: Binding<Item?>,
        contentDisplayMode: MediaGalleryContentDisplayMode = .fill,
        layout: MediaGalleryLayout = .standard,
        zoomBehavior: ZoomableViewBehavior = .init(),
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String = { "Media item \($0.id)" },
        canLoadMore: Bool = true,
        isLoadingMore: Bool = false,
        onLoadMore: @escaping () -> Void = {},
        @ViewBuilder thumbnailContent: @escaping (Item) -> Thumbnail,
        @ViewBuilder detailContent: @escaping (Item) -> DetailContent,
        @ViewBuilder emptyStateContent: @escaping () -> EmptyContent,
        @ToolbarContentBuilder detailToolbarContent: @escaping (Item) -> DetailToolbar
    ) {
        self.init(
            items: items,
            selection: selection,
            contentDisplayMode: contentDisplayMode,
            layout: layout,
            zoomBehavior: zoomBehavior,
            contentAspectRatio: contentAspectRatio,
            accessibilityLabel: accessibilityLabel,
            canLoadMore: canLoadMore,
            isLoadingMore: isLoadingMore,
            onLoadMore: onLoadMore,
            thumbnailContent: thumbnailContent,
            detailContent: detailContent,
            overlayContent: { _ in EmptyView() },
            emptyStateContent: emptyStateContent,
            detailToolbarContent: detailToolbarContent
        )
    }
}

extension MediaGalleryView
where OverlayContent == EmptyView, DetailToolbar == MediaGalleryEmptyToolbarContent {
    /// 그리드 오버레이 콘텐츠와 상세 toolbar 콘텐츠 없이 미디어 갤러리 흐름을 만듭니다.
    public init(
        items: [Item],
        selection: Binding<Item?>,
        contentDisplayMode: MediaGalleryContentDisplayMode = .fill,
        layout: MediaGalleryLayout = .standard,
        zoomBehavior: ZoomableViewBehavior = .init(),
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String = { "Media item \($0.id)" },
        canLoadMore: Bool = true,
        isLoadingMore: Bool = false,
        onLoadMore: @escaping () -> Void = {},
        @ViewBuilder thumbnailContent: @escaping (Item) -> Thumbnail,
        @ViewBuilder detailContent: @escaping (Item) -> DetailContent,
        @ViewBuilder emptyStateContent: @escaping () -> EmptyContent
    ) {
        self.init(
            items: items,
            selection: selection,
            contentDisplayMode: contentDisplayMode,
            layout: layout,
            zoomBehavior: zoomBehavior,
            contentAspectRatio: contentAspectRatio,
            accessibilityLabel: accessibilityLabel,
            loadMoreBehavior: MediaGalleryLoadMoreBehavior(
                canLoadMore: canLoadMore,
                isLoadingMore: isLoadingMore,
                onLoadMore: onLoadMore
            ),
            thumbnailContent: thumbnailContent,
            detailContent: detailContent,
            overlayContent: { _ in EmptyView() },
            emptyStateContent: emptyStateContent,
            detailToolbarContent: { _ in
                MediaGalleryEmptyToolbarContent()
            }
        )
    }
}

extension MediaGalleryView where EmptyContent == EmptyView {
    /// 빈 상태 콘텐츠 없이 미디어 갤러리 흐름을 만듭니다.
    public init(
        items: [Item],
        selection: Binding<Item?>,
        contentDisplayMode: MediaGalleryContentDisplayMode = .fill,
        layout: MediaGalleryLayout = .standard,
        zoomBehavior: ZoomableViewBehavior = .init(),
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String = { "Media item \($0.id)" },
        canLoadMore: Bool = true,
        isLoadingMore: Bool = false,
        onLoadMore: @escaping () -> Void = {},
        @ViewBuilder thumbnailContent: @escaping (Item) -> Thumbnail,
        @ViewBuilder detailContent: @escaping (Item) -> DetailContent,
        @ViewBuilder overlayContent: @escaping (Item) -> OverlayContent,
        @ToolbarContentBuilder detailToolbarContent: @escaping (Item) -> DetailToolbar
    ) {
        self.init(
            items: items,
            selection: selection,
            contentDisplayMode: contentDisplayMode,
            layout: layout,
            zoomBehavior: zoomBehavior,
            contentAspectRatio: contentAspectRatio,
            accessibilityLabel: accessibilityLabel,
            canLoadMore: canLoadMore,
            isLoadingMore: isLoadingMore,
            onLoadMore: onLoadMore,
            thumbnailContent: thumbnailContent,
            detailContent: detailContent,
            overlayContent: overlayContent,
            emptyStateContent: { EmptyView() },
            detailToolbarContent: detailToolbarContent
        )
    }
}

extension MediaGalleryView
where EmptyContent == EmptyView, DetailToolbar == MediaGalleryEmptyToolbarContent {
    /// 빈 상태 콘텐츠와 상세 toolbar 콘텐츠 없이 미디어 갤러리 흐름을 만듭니다.
    public init(
        items: [Item],
        selection: Binding<Item?>,
        contentDisplayMode: MediaGalleryContentDisplayMode = .fill,
        layout: MediaGalleryLayout = .standard,
        zoomBehavior: ZoomableViewBehavior = .init(),
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String = { "Media item \($0.id)" },
        canLoadMore: Bool = true,
        isLoadingMore: Bool = false,
        onLoadMore: @escaping () -> Void = {},
        @ViewBuilder thumbnailContent: @escaping (Item) -> Thumbnail,
        @ViewBuilder detailContent: @escaping (Item) -> DetailContent,
        @ViewBuilder overlayContent: @escaping (Item) -> OverlayContent
    ) {
        self.init(
            items: items,
            selection: selection,
            contentDisplayMode: contentDisplayMode,
            layout: layout,
            zoomBehavior: zoomBehavior,
            contentAspectRatio: contentAspectRatio,
            accessibilityLabel: accessibilityLabel,
            loadMoreBehavior: MediaGalleryLoadMoreBehavior(
                canLoadMore: canLoadMore,
                isLoadingMore: isLoadingMore,
                onLoadMore: onLoadMore
            ),
            thumbnailContent: thumbnailContent,
            detailContent: detailContent,
            overlayContent: overlayContent,
            emptyStateContent: { EmptyView() },
            detailToolbarContent: { _ in
                MediaGalleryEmptyToolbarContent()
            }
        )
    }
}

extension MediaGalleryView
where OverlayContent == EmptyView, EmptyContent == EmptyView {
    /// 썸네일, 상세 콘텐츠, 상세 toolbar 콘텐츠만으로 미디어 갤러리 흐름을 만듭니다.
    public init(
        items: [Item],
        selection: Binding<Item?>,
        contentDisplayMode: MediaGalleryContentDisplayMode = .fill,
        layout: MediaGalleryLayout = .standard,
        zoomBehavior: ZoomableViewBehavior = .init(),
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String = { "Media item \($0.id)" },
        canLoadMore: Bool = true,
        isLoadingMore: Bool = false,
        onLoadMore: @escaping () -> Void = {},
        @ViewBuilder thumbnailContent: @escaping (Item) -> Thumbnail,
        @ViewBuilder detailContent: @escaping (Item) -> DetailContent,
        @ToolbarContentBuilder detailToolbarContent: @escaping (Item) -> DetailToolbar
    ) {
        self.init(
            items: items,
            selection: selection,
            contentDisplayMode: contentDisplayMode,
            layout: layout,
            zoomBehavior: zoomBehavior,
            contentAspectRatio: contentAspectRatio,
            accessibilityLabel: accessibilityLabel,
            canLoadMore: canLoadMore,
            isLoadingMore: isLoadingMore,
            onLoadMore: onLoadMore,
            thumbnailContent: thumbnailContent,
            detailContent: detailContent,
            overlayContent: { _ in EmptyView() },
            emptyStateContent: { EmptyView() },
            detailToolbarContent: detailToolbarContent
        )
    }

    /// 썸네일과 상세 콘텐츠만으로 미디어 갤러리 흐름을 만듭니다.
    public init(
        items: [Item],
        selection: Binding<Item?>,
        contentDisplayMode: MediaGalleryContentDisplayMode = .fill,
        layout: MediaGalleryLayout = .standard,
        zoomBehavior: ZoomableViewBehavior = .init(),
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String = { "Media item \($0.id)" },
        canLoadMore: Bool = true,
        isLoadingMore: Bool = false,
        onLoadMore: @escaping () -> Void = {},
        @ViewBuilder thumbnailContent: @escaping (Item) -> Thumbnail,
        @ViewBuilder detailContent: @escaping (Item) -> DetailContent
    ) where DetailToolbar == MediaGalleryEmptyToolbarContent {
        self.init(
            items: items,
            selection: selection,
            contentDisplayMode: contentDisplayMode,
            layout: layout,
            zoomBehavior: zoomBehavior,
            contentAspectRatio: contentAspectRatio,
            accessibilityLabel: accessibilityLabel,
            loadMoreBehavior: MediaGalleryLoadMoreBehavior(
                canLoadMore: canLoadMore,
                isLoadingMore: isLoadingMore,
                onLoadMore: onLoadMore
            ),
            thumbnailContent: thumbnailContent,
            detailContent: detailContent,
            overlayContent: { _ in EmptyView() },
            emptyStateContent: { EmptyView() },
            detailToolbarContent: { _ in
                MediaGalleryEmptyToolbarContent()
            }
        )
    }
}
