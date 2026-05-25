import SwiftUI

/// 상세 화면 toolbar 콘텐츠가 없음을 나타내는 기본 타입입니다.
public struct MediaGalleryEmptyToolbarContent: ToolbarContent {
    /// 빈 상세 toolbar 콘텐츠를 만듭니다.
    public init() {}

    public var body: some ToolbarContent {
        ToolbarItemGroup {}
    }
}

struct MediaGalleryLoadMoreBehavior {
    let canLoadMore: Bool
    let isLoadingMore: Bool

    private let onLoadMore: () -> Void

    init(
        canLoadMore: Bool,
        isLoadingMore: Bool,
        onLoadMore: @escaping () -> Void
    ) {
        self.canLoadMore = canLoadMore
        self.isLoadingMore = isLoadingMore
        self.onLoadMore = onLoadMore
    }

    func loadMore() {
        onLoadMore()
    }
}

/// `NavigationStack` 안에서 사용하는 그리드-상세 미디어 갤러리 흐름입니다.
public struct MediaGalleryView<
    Item: Identifiable,
    Thumbnail: View,
    DetailContent: View,
    OverlayContent: View,
    EmptyContent: View,
    DetailToolbar: ToolbarContent
>: View {
    private let items: [Item]
    private let contentDisplayMode: MediaGalleryContentDisplayMode
    private let layout: MediaGalleryLayout
    private let zoomBehavior: ZoomableViewBehavior
    private let contentAspectRatio: (Item) -> CGFloat?
    private let accessibilityLabel: (Item) -> String
    private let loadMoreBehavior: MediaGalleryLoadMoreBehavior
    private let thumbnailContent: (Item) -> Thumbnail
    private let detailContent: (Item) -> DetailContent
    private let overlayContent: (Item) -> OverlayContent
    private let emptyStateContent: () -> EmptyContent
    private let detailToolbarContent: (Item) -> DetailToolbar

    @Binding private var selection: Item?
    @Namespace private var transitionNamespace

    init(
        items: [Item],
        selection: Binding<Item?>,
        contentDisplayMode: MediaGalleryContentDisplayMode,
        layout: MediaGalleryLayout,
        zoomBehavior: ZoomableViewBehavior,
        contentAspectRatio: @escaping (Item) -> CGFloat?,
        accessibilityLabel: @escaping (Item) -> String,
        loadMoreBehavior: MediaGalleryLoadMoreBehavior,
        @ViewBuilder thumbnailContent: @escaping (Item) -> Thumbnail,
        @ViewBuilder detailContent: @escaping (Item) -> DetailContent,
        @ViewBuilder overlayContent: @escaping (Item) -> OverlayContent,
        @ViewBuilder emptyStateContent: @escaping () -> EmptyContent,
        detailToolbarContent: @escaping (Item) -> DetailToolbar
    ) {
        self.items = items
        self.contentDisplayMode = contentDisplayMode
        self.layout = layout
        self.zoomBehavior = zoomBehavior
        self.contentAspectRatio = contentAspectRatio
        self.accessibilityLabel = accessibilityLabel
        self.loadMoreBehavior = loadMoreBehavior
        self.thumbnailContent = thumbnailContent
        self.detailContent = detailContent
        self.overlayContent = overlayContent
        self.emptyStateContent = emptyStateContent
        self.detailToolbarContent = detailToolbarContent
        self._selection = selection
    }

    /// 미디어 갤러리 흐름을 만듭니다.
    ///
    /// 이 뷰는 `NavigationStack` 안에 배치합니다. 상세 화면의 앱별 액션이나
    /// 보조 컨트롤은 `detailToolbarContent`로 제공합니다.
    ///
    /// - Parameters:
    ///   - items: 그리드와 상세 뷰어에 표시할 미디어 항목입니다.
    ///   - selection: 상세 화면에 현재 선택된 항목입니다.
    ///   - contentDisplayMode: 고정된 그리드 셀 안에서 콘텐츠를 배치하는 방식입니다.
    ///   - layout: 그리드 간격, 적응형 항목 너비, 셀 비율 설정입니다.
    ///   - zoomBehavior: 상세 콘텐츠에 사용할 확대/축소 제스처 동작입니다.
    ///   - contentAspectRatio: 각 항목의 선택적 콘텐츠 가로세로 비율입니다.
    ///   - accessibilityLabel: 각 그리드 항목의 VoiceOver 라벨입니다.
    ///   - canLoadMore: 시각적 끝에 도달했을 때 더 많은 항목을 요청할지 여부입니다.
    ///   - isLoadingMore: 추가 항목을 불러오는 동안 하단 진행 표시기를 보일지 여부입니다.
    ///   - onLoadMore: 마지막 항목이 보여 추가 콘텐츠가 필요할 때 호출됩니다.
    ///   - thumbnailContent: 각 항목의 그리드 썸네일 콘텐츠를 만듭니다.
    ///   - detailContent: 각 항목의 상세 페이지 콘텐츠를 만듭니다.
    ///   - overlayContent: 각 전체 그리드 셀 위에 표시할 오버레이를 만듭니다.
    ///   - emptyStateContent: `items`가 비어 있을 때 표시할 뷰를 만듭니다.
    ///   - detailToolbarContent: 선택된 항목에 맞는 상세 화면 toolbar 콘텐츠를 만듭니다.
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
            loadMoreBehavior: MediaGalleryLoadMoreBehavior(
                canLoadMore: canLoadMore,
                isLoadingMore: isLoadingMore,
                onLoadMore: onLoadMore
            ),
            thumbnailContent: thumbnailContent,
            detailContent: detailContent,
            overlayContent: overlayContent,
            emptyStateContent: emptyStateContent,
            detailToolbarContent: detailToolbarContent
        )
    }

    public var body: some View {
        MediaGalleryNavigationGrid(
            items: items,
            selection: $selection,
            contentDisplayMode: contentDisplayMode,
            layout: layout,
            transitionNamespace: transitionNamespace,
            contentAspectRatio: contentAspectRatio,
            accessibilityLabel: accessibilityLabel,
            loadMoreBehavior: loadMoreBehavior,
            thumbnailContent: thumbnailContent,
            overlayContent: overlayContent,
            emptyStateContent: emptyStateContent
        )
        .mediaGalleryHiddenBottomBar()
        .navigationDestination(
            for: MediaGalleryNavigationRoute<Item.ID>.self
        ) { route in
            MediaGalleryNavigationDetailDestination(
                items: items,
                selection: $selection,
                sourceItemID: route.itemID,
                zoomBehavior: zoomBehavior,
                transitionNamespace: transitionNamespace,
                contentAspectRatio: contentAspectRatio,
                detailContent: detailContent,
                detailToolbarContent: detailToolbarContent
            )
        }
    }
}

extension View {
    @ViewBuilder
    fileprivate func mediaGalleryHiddenBottomBar() -> some View {
        #if os(iOS)
            toolbar(.hidden, for: .bottomBar)
        #else
            self
        #endif
    }
}
