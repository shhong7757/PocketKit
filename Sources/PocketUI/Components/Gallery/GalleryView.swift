import Foundation
import SwiftUI

/// 항목 컬렉션을 선택 가능한 그리드 기반 갤러리로 표시합니다.
public struct GalleryView<
    Item: Identifiable,
    Content: View,
    OverlayContent: View,
    EmptyContent: View
>: View {
    private let items: [Item]
    private let selection: GallerySelection<Item.ID>
    private let layout: GalleryLayout
    private let zoomTransition: GalleryZoomTransition<Item.ID>?
    private let scrollPosition: Binding<ScrollPosition>?
    private let contentAspectRatio: (Item) -> CGFloat?
    private let accessibilityLabel: (Item) -> String
    private let pagination: GalleryPagination
    private let onRefresh: (@Sendable () async -> Void)?
    private let onTap: ((Item) -> Void)?
    private let content: (Item) -> Content
    private let overlayContent: (Item) -> OverlayContent
    private let emptyContent: () -> EmptyContent

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
        pagination: GalleryPagination = .disabled,
        onRefresh: (@Sendable () async -> Void)? = nil,
        onTap: ((Item) -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder overlayContent: @escaping (Item) -> OverlayContent,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) {
        self.items = items
        self.selection = selection
        self.layout = layout
        self.zoomTransition = zoomTransition
        self.scrollPosition = scrollPosition
        self.contentAspectRatio = contentAspectRatio
        self.accessibilityLabel = accessibilityLabel
        self.pagination = pagination
        self.onRefresh = onRefresh
        self.onTap = onTap
        self.content = content
        self.overlayContent = overlayContent
        self.emptyContent = emptyContent
    }

    public var body: some View {
        ScrollView {
            if items.isEmpty {
                emptyContent()
                    .frame(maxWidth: .infinity)
                    .padding(layout.resolvedContentInsets.edgeInsets)
            } else {
                LazyVGrid(
                    columns: layout.columns,
                    spacing: layout.resolvedSpacing
                ) {
                    ForEach(items) { item in
                        galleryCell(for: item)
                    }
                }
                .scrollTargetLayout()
                .padding(layout.resolvedContentInsets.edgeInsets)

                if pagination.isFetchingNextPage {
                    nextPageLoadingIndicator()
                }
            }
        }
        .modifier(GalleryScrollPositionModifier(scrollPosition: scrollPosition))
        .modifier(GalleryPullToRefreshModifier(onRefresh: onRefresh))
        .scrollIndicators(layout.showsScrollIndicators ? .visible : .hidden)
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
        .onAppear {
            handleItemDidAppear(item.id)
        }
        .onDisappear {
            handleItemDidDisappear(item.id)
        }
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
                max(.space3, layout.resolvedSpacing * 2)
            )
            .accessibilityLabel(
                Text(GalleryAccessibilityText.fetchingNextPage)
            )
    }
}

private extension GalleryView {
    var canRequestNextPage: Bool {
        pagination.hasNextPage && !pagination.isFetchingNextPage
    }

    func handleItemDidAppear(_ id: Item.ID) {
        if paginationState.recordAppearance(
            of: id,
            itemIDs: currentItemIDs,
            canRequestNextPage: canRequestNextPage,
            threshold: pagination.resolvedThreshold
        ) {
            pagination.requestNextPage()
        }
    }

    func handleItemDidDisappear(_ id: Item.ID) {
        paginationState.recordDisappearance(of: id)
    }

    func handleItemIDsChange(to itemIDs: [Item.ID]) {
        paginationState.syncVisibleItems(with: itemIDs)
        requestNextPageIfNeeded()
    }

    func handleHasNextPageChange(
        from oldValue: Bool,
        to newValue: Bool
    ) {
        guard !oldValue && newValue else { return }

        paginationState.allowRetryForCurrentItems()
        requestNextPageIfNeeded()
    }

    func handleIsFetchingNextPageChange(
        from oldValue: Bool,
        to newValue: Bool
    ) {
        guard oldValue && !newValue else { return }

        paginationState.allowRetryForCurrentItems()
        requestNextPageIfNeeded()
    }

    func requestNextPageIfNeeded() {
        if paginationState.requestNextPageIfNeeded(
            itemIDs: currentItemIDs,
            canRequestNextPage: canRequestNextPage,
            threshold: pagination.resolvedThreshold
        ) {
            pagination.requestNextPage()
        }
    }
}

extension GalleryView where OverlayContent == EmptyView {
    /// 오버레이 콘텐츠 없이 갤러리를 만듭니다.
    public init(
        items: [Item],
        selection: GallerySelection<Item.ID> = .none,
        layout: GalleryLayout = .standard,
        zoomTransition: GalleryZoomTransition<Item.ID>? = nil,
        scrollPosition: Binding<ScrollPosition>? = nil,
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String,
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
            pagination: pagination,
            onRefresh: onRefresh,
            onTap: onTap,
            content: content,
            overlayContent: { _ in EmptyView() },
            emptyContent: emptyContent
        )
    }
}

extension GalleryView where EmptyContent == EmptyView {
    /// 빈 상태 콘텐츠 없이 갤러리를 만듭니다.
    public init(
        items: [Item],
        selection: GallerySelection<Item.ID> = .none,
        layout: GalleryLayout = .standard,
        zoomTransition: GalleryZoomTransition<Item.ID>? = nil,
        scrollPosition: Binding<ScrollPosition>? = nil,
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String,
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
            pagination: pagination,
            onRefresh: onRefresh,
            onTap: onTap,
            content: content,
            overlayContent: overlayContent,
            emptyContent: { EmptyView() }
        )
    }
}

extension GalleryView where OverlayContent == EmptyView, EmptyContent == EmptyView {
    /// 빈 상태 콘텐츠 없이 갤러리를 만듭니다.
    public init(
        items: [Item],
        selection: GallerySelection<Item.ID> = .none,
        layout: GalleryLayout = .standard,
        zoomTransition: GalleryZoomTransition<Item.ID>? = nil,
        scrollPosition: Binding<ScrollPosition>? = nil,
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (Item) -> String,
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
            pagination: pagination,
            onRefresh: onRefresh,
            onTap: onTap,
            content: content,
            overlayContent: { _ in EmptyView() },
            emptyContent: { EmptyView() }
        )
    }
}
