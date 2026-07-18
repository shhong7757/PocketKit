// swiftlint:disable file_length
import Foundation
import SwiftUI

/// 항목 컬렉션을 선택 가능한 그리드 기반 갤러리로 표시합니다.
public struct GalleryView<
    Item: Identifiable,
    Content: View,
    OverlayContent: View,
    EmptyContent: View,
    HeaderContent: View,
    FooterContent: View
>: View {
    private let items: [Item]
    private let selection: GallerySelection<Item.ID>
    private let layout: GalleryLayout
    private let zoomTransition: GalleryZoomTransition<Item.ID>?
    private let scrollPosition: Binding<ScrollPosition>?
    private let contentAspectRatio: (Item) -> CGFloat?
    private let accessibilityLabel: (Item) -> String
    private let accessibilityValue: (Item) -> String?
    private let pagination: GalleryPagination
    private let onRefresh: (@Sendable () async -> Void)?
    private let onTap: ((Item) -> Void)?
    private let headerContent: () -> HeaderContent
    private let content: (Item) -> Content
    private let overlayContent: (Item) -> OverlayContent
    private let emptyContent: () -> EmptyContent
    private let footerContent: () -> FooterContent

    @State private var paginationState =
        GalleryPagination.State<Item.ID>()

    private var currentItemIDs: [Item.ID] {
        items.map(\.id)
    }

    private var isSelectionModeEnabled: Bool {
        switch selection {
        case .none:
            return false
        case .multiple:
            return true
        }
    }

    private var isCellTapEnabled: Bool {
        onTap != nil || isSelectionModeEnabled
    }

    /// 갤러리를 만듭니다.
    public init(
        items: [Item],
        selection: GallerySelection<Item.ID> = .none,
        layout: GalleryLayout = .standard,
        zoomTransition: GalleryZoomTransition<Item.ID>? = nil,
        scrollPosition: Binding<ScrollPosition>? = nil,
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String,
        accessibilityValue: @escaping (Item) -> String? = { _ in nil },
        pagination: GalleryPagination = .disabled,
        onRefresh: (@Sendable () async -> Void)? = nil,
        onTap: ((Item) -> Void)? = nil,
        @ViewBuilder headerContent: @escaping () -> HeaderContent,
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder overlayContent: @escaping (Item) -> OverlayContent,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent,
        @ViewBuilder footerContent: @escaping () -> FooterContent
    ) {
        self.items = items
        self.selection = selection
        self.layout = layout
        self.zoomTransition = zoomTransition
        self.scrollPosition = scrollPosition
        self.contentAspectRatio = contentAspectRatio
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityValue = accessibilityValue
        self.pagination = pagination
        self.onRefresh = onRefresh
        self.onTap = onTap
        self.headerContent = headerContent
        self.content = content
        self.overlayContent = overlayContent
        self.emptyContent = emptyContent
        self.footerContent = footerContent
    }

    public var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    headerContent()
                        .frame(maxWidth: .infinity)

                    if items.isEmpty {
                        Spacer(minLength: 0)
                        emptyContent()
                            .frame(maxWidth: .infinity)
                        Spacer(minLength: 0)
                    } else {
                        LazyVGrid(
                            columns: layout.columns,
                            spacing: layout.resolvedGap
                        ) {
                            ForEach(items) { item in
                                galleryCell(for: item)
                            }
                        }
                        .scrollTargetLayout()

                        if pagination.isFetchingNextPage {
                            nextPageLoadingIndicator()
                        }
                    }

                    footerContent()
                        .frame(maxWidth: .infinity)
                }
                .frame(
                    minHeight: proxy.size.height,
                    alignment: .top
                )
                .padding(layout.resolvedContentPadding.edgeInsets)
            }
            .modifier(GalleryScrollPositionModifier(scrollPosition: scrollPosition))
            .modifier(GalleryPullToRefreshModifier(onRefresh: onRefresh))
            .scrollIndicators(layout.showsScrollIndicators ? .visible : .hidden)
            .onScrollTargetVisibilityChange(
                idType: Item.ID.self,
                threshold: pagination.resolvedVisibilityThreshold
            ) { visibleIDs in
                handleVisibleItemIDsChange(visibleIDs)
            }
            .onChange(of: currentItemIDs) { _, newItemIDs in
                handleItemIDsChange(to: newItemIDs)
            }
            .onChange(of: pagination.hasNextPage) { oldValue, newValue in
                handleHasNextPageChange(
                    from: oldValue,
                    to: newValue
                )
            }
            .onChange(of: pagination.isFetchingNextPage) { oldValue, newValue in
                handleIsFetchingNextPageChange(
                    from: oldValue,
                    to: newValue
                )
            }
        }
    }

    private func galleryCell(for item: Item) -> some View {
        let isSelected = selection.contains(item.id)

        return GalleryCell(
            contentMode: layout.contentMode,
            cellAspectRatio: layout.resolvedCellAspectRatio,
            contentAspectRatio: contentAspectRatio(item),
            isSelected: isSelected,
            showsSelectionIndicator: isSelectionModeEnabled,
            hasTapAction: isCellTapEnabled,
            accessibilityLabel: accessibilityLabel(item),
            contentAccessibilityValue: accessibilityValue(item),
            content: content(item),
            overlayContent: overlayContent(item)
        )
        .modifier(
            GalleryZoomTransitionSourceModifier(
                sourceID: item.id,
                zoomTransition: zoomTransition
            )
        )
        .modifier(
            GalleryCellTapActionModifier(
                isEnabled: isCellTapEnabled,
                tapAction: {
                    handleCellTap(for: item)
                }
            )
        )
        .id(item.id)
    }

    private func handleCellTap(for item: Item) {
        guard !selection.toggleSelection(for: item.id) else {
            return
        }

        zoomTransition?.activateSourceID(item.id)
        onTap?(item)
    }

    private func nextPageLoadingIndicator() -> some View {
        ProgressView()
            .controlSize(.regular)
            .frame(maxWidth: .infinity)
            .padding(
                .vertical,
                max(.space3, layout.resolvedGap * 2)
            )
            .accessibilityLabel(
                Text(GalleryAccessibilityText.fetchingNextPage)
            )
    }
}

extension GalleryView {
    fileprivate var canRequestNextPage: Bool {
        pagination.hasNextPage && !pagination.isFetchingNextPage
    }

    fileprivate func handleVisibleItemIDsChange(_ visibleIDs: [Item.ID]) {
        if paginationState.recordVisibleItems(
            visibleIDs,
            itemIDs: currentItemIDs,
            canRequestNextPage: canRequestNextPage
        ) {
            pagination.requestNextPage()
        }
    }

    fileprivate func handleItemIDsChange(to itemIDs: [Item.ID]) {
        paginationState.syncVisibleItems(with: itemIDs)
        requestNextPageIfNeeded()
    }

    fileprivate func handleHasNextPageChange(
        from oldValue: Bool,
        to newValue: Bool
    ) {
        guard !oldValue && newValue else { return }

        paginationState.allowRetryForCurrentItems()
        requestNextPageIfNeeded()
    }

    fileprivate func handleIsFetchingNextPageChange(
        from oldValue: Bool,
        to newValue: Bool
    ) {
        guard oldValue && !newValue else { return }

        // Re-evaluate only after the request completes. The page boundary
        // remains locked, so a failed request cannot immediately retry itself.
        requestNextPageIfNeeded()
    }

    fileprivate func requestNextPageIfNeeded() {
        if paginationState.requestNextPageIfNeeded(
            itemIDs: currentItemIDs,
            canRequestNextPage: canRequestNextPage
        ) {
            pagination.requestNextPage()
        }
    }
}

extension GalleryView where HeaderContent == EmptyView, FooterContent == EmptyView {
    /// 헤더와 푸터 콘텐츠 없이 갤러리를 만듭니다.
    public init(
        items: [Item],
        selection: GallerySelection<Item.ID> = .none,
        layout: GalleryLayout = .standard,
        zoomTransition: GalleryZoomTransition<Item.ID>? = nil,
        scrollPosition: Binding<ScrollPosition>? = nil,
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String,
        accessibilityValue: @escaping (Item) -> String? = { _ in nil },
        pagination: GalleryPagination = .disabled,
        onRefresh: (@Sendable () async -> Void)? = nil,
        onTap: ((Item) -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder overlayContent: @escaping (Item) -> OverlayContent,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) {
        self.init(
            items: items,
            selection: selection,
            layout: layout,
            zoomTransition: zoomTransition,
            scrollPosition: scrollPosition,
            contentAspectRatio: contentAspectRatio,
            accessibilityLabel: accessibilityLabel,
            accessibilityValue: accessibilityValue,
            pagination: pagination,
            onRefresh: onRefresh,
            onTap: onTap,
            headerContent: { EmptyView() },
            content: content,
            overlayContent: overlayContent,
            emptyContent: emptyContent,
            footerContent: { EmptyView() }
        )
    }
}

extension GalleryView
where OverlayContent == EmptyView, HeaderContent == EmptyView, FooterContent == EmptyView {
    /// 오버레이, 헤더, 푸터 콘텐츠 없이 갤러리를 만듭니다.
    public init(
        items: [Item],
        selection: GallerySelection<Item.ID> = .none,
        layout: GalleryLayout = .standard,
        zoomTransition: GalleryZoomTransition<Item.ID>? = nil,
        scrollPosition: Binding<ScrollPosition>? = nil,
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String,
        accessibilityValue: @escaping (Item) -> String? = { _ in nil },
        pagination: GalleryPagination = .disabled,
        onRefresh: (@Sendable () async -> Void)? = nil,
        onTap: ((Item) -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) {
        self.init(
            items: items,
            selection: selection,
            layout: layout,
            zoomTransition: zoomTransition,
            scrollPosition: scrollPosition,
            contentAspectRatio: contentAspectRatio,
            accessibilityLabel: accessibilityLabel,
            accessibilityValue: accessibilityValue,
            pagination: pagination,
            onRefresh: onRefresh,
            onTap: onTap,
            headerContent: { EmptyView() },
            content: content,
            overlayContent: { _ in EmptyView() },
            emptyContent: emptyContent,
            footerContent: { EmptyView() }
        )
    }
}

extension GalleryView
where EmptyContent == EmptyView, HeaderContent == EmptyView, FooterContent == EmptyView {
    /// 빈 상태, 헤더, 푸터 콘텐츠 없이 갤러리를 만듭니다.
    public init(
        items: [Item],
        selection: GallerySelection<Item.ID> = .none,
        layout: GalleryLayout = .standard,
        zoomTransition: GalleryZoomTransition<Item.ID>? = nil,
        scrollPosition: Binding<ScrollPosition>? = nil,
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String,
        accessibilityValue: @escaping (Item) -> String? = { _ in nil },
        pagination: GalleryPagination = .disabled,
        onRefresh: (@Sendable () async -> Void)? = nil,
        onTap: ((Item) -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder overlayContent: @escaping (Item) -> OverlayContent
    ) {
        self.init(
            items: items,
            selection: selection,
            layout: layout,
            zoomTransition: zoomTransition,
            scrollPosition: scrollPosition,
            contentAspectRatio: contentAspectRatio,
            accessibilityLabel: accessibilityLabel,
            accessibilityValue: accessibilityValue,
            pagination: pagination,
            onRefresh: onRefresh,
            onTap: onTap,
            headerContent: { EmptyView() },
            content: content,
            overlayContent: overlayContent,
            emptyContent: { EmptyView() },
            footerContent: { EmptyView() }
        )
    }
}

// swiftlint:disable opening_brace
extension GalleryView
where
    OverlayContent == EmptyView,
    EmptyContent == EmptyView,
    HeaderContent == EmptyView,
    FooterContent == EmptyView
{
    /// 오버레이, 빈 상태, 헤더, 푸터 콘텐츠 없이 갤러리를 만듭니다.
    public init(
        items: [Item],
        selection: GallerySelection<Item.ID> = .none,
        layout: GalleryLayout = .standard,
        zoomTransition: GalleryZoomTransition<Item.ID>? = nil,
        scrollPosition: Binding<ScrollPosition>? = nil,
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String,
        accessibilityValue: @escaping (Item) -> String? = { _ in nil },
        pagination: GalleryPagination = .disabled,
        onRefresh: (@Sendable () async -> Void)? = nil,
        onTap: ((Item) -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.init(
            items: items,
            selection: selection,
            layout: layout,
            zoomTransition: zoomTransition,
            scrollPosition: scrollPosition,
            contentAspectRatio: contentAspectRatio,
            accessibilityLabel: accessibilityLabel,
            accessibilityValue: accessibilityValue,
            pagination: pagination,
            onRefresh: onRefresh,
            onTap: onTap,
            headerContent: { EmptyView() },
            content: content,
            overlayContent: { _ in EmptyView() },
            emptyContent: { EmptyView() },
            footerContent: { EmptyView() }
        )
    }
}
// swiftlint:enable opening_brace

extension GalleryView
where OverlayContent == EmptyView, EmptyContent == EmptyView, HeaderContent == EmptyView {
    /// 푸터 콘텐츠가 있는 갤러리를 만듭니다.
    public init(
        items: [Item],
        selection: GallerySelection<Item.ID> = .none,
        layout: GalleryLayout = .standard,
        zoomTransition: GalleryZoomTransition<Item.ID>? = nil,
        scrollPosition: Binding<ScrollPosition>? = nil,
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String,
        accessibilityValue: @escaping (Item) -> String? = { _ in nil },
        pagination: GalleryPagination = .disabled,
        onRefresh: (@Sendable () async -> Void)? = nil,
        onTap: ((Item) -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder footerContent: @escaping () -> FooterContent
    ) {
        self.init(
            items: items,
            selection: selection,
            layout: layout,
            zoomTransition: zoomTransition,
            scrollPosition: scrollPosition,
            contentAspectRatio: contentAspectRatio,
            accessibilityLabel: accessibilityLabel,
            accessibilityValue: accessibilityValue,
            pagination: pagination,
            onRefresh: onRefresh,
            onTap: onTap,
            headerContent: { EmptyView() },
            content: content,
            overlayContent: { _ in EmptyView() },
            emptyContent: { EmptyView() },
            footerContent: footerContent
        )
    }
}

extension GalleryView
where OverlayContent == EmptyView, EmptyContent == EmptyView, FooterContent == EmptyView {
    /// 헤더 콘텐츠가 있는 갤러리를 만듭니다.
    public init(
        items: [Item],
        selection: GallerySelection<Item.ID> = .none,
        layout: GalleryLayout = .standard,
        zoomTransition: GalleryZoomTransition<Item.ID>? = nil,
        scrollPosition: Binding<ScrollPosition>? = nil,
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String,
        accessibilityValue: @escaping (Item) -> String? = { _ in nil },
        pagination: GalleryPagination = .disabled,
        onRefresh: (@Sendable () async -> Void)? = nil,
        onTap: ((Item) -> Void)? = nil,
        @ViewBuilder headerContent: @escaping () -> HeaderContent,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.init(
            items: items,
            selection: selection,
            layout: layout,
            zoomTransition: zoomTransition,
            scrollPosition: scrollPosition,
            contentAspectRatio: contentAspectRatio,
            accessibilityLabel: accessibilityLabel,
            accessibilityValue: accessibilityValue,
            pagination: pagination,
            onRefresh: onRefresh,
            onTap: onTap,
            headerContent: headerContent,
            content: content,
            overlayContent: { _ in EmptyView() },
            emptyContent: { EmptyView() },
            footerContent: { EmptyView() }
        )
    }
}

extension GalleryView where OverlayContent == EmptyView, EmptyContent == EmptyView {
    /// 헤더와 푸터 콘텐츠가 있는 갤러리를 만듭니다.
    public init(
        items: [Item],
        selection: GallerySelection<Item.ID> = .none,
        layout: GalleryLayout = .standard,
        zoomTransition: GalleryZoomTransition<Item.ID>? = nil,
        scrollPosition: Binding<ScrollPosition>? = nil,
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String,
        accessibilityValue: @escaping (Item) -> String? = { _ in nil },
        pagination: GalleryPagination = .disabled,
        onRefresh: (@Sendable () async -> Void)? = nil,
        onTap: ((Item) -> Void)? = nil,
        @ViewBuilder headerContent: @escaping () -> HeaderContent,
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder footerContent: @escaping () -> FooterContent
    ) {
        self.init(
            items: items,
            selection: selection,
            layout: layout,
            zoomTransition: zoomTransition,
            scrollPosition: scrollPosition,
            contentAspectRatio: contentAspectRatio,
            accessibilityLabel: accessibilityLabel,
            accessibilityValue: accessibilityValue,
            pagination: pagination,
            onRefresh: onRefresh,
            onTap: onTap,
            headerContent: headerContent,
            content: content,
            overlayContent: { _ in EmptyView() },
            emptyContent: { EmptyView() },
            footerContent: footerContent
        )
    }
}
