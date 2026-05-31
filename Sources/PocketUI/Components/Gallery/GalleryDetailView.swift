import SwiftUI

/// 갤러리 항목을 페이지 형태로 보여주는 상세 뷰어입니다.
public struct GalleryDetailView<
    Item: Identifiable,
    Content: View,
    EmptyContent: View
>: View {
    private let items: [Item]
    private let sourceItemID: Item.ID
    private let zoomTransition: GalleryZoomTransition<Item.ID>?
    private let zoomBehavior: ZoomableViewBehavior
    private let contentAspectRatio: (Item) -> CGFloat?
    private let onActiveItemChange: (Item.ID) -> Void
    private let content: (Item) -> Content
    private let emptyContent: () -> EmptyContent

    @Binding private var activeItemID: Item.ID?
    @State private var currentPageID: Item.ID?
    @State private var lastNotifiedActiveItemID: Item.ID?
    @State private var zoomedItemIDs: Set<Item.ID> = []

    /// 갤러리 상세 뷰어를 만듭니다.
    ///
    /// `sourceItemID`는 상세 화면을 연 그리드 항목입니다. `activeItemID`는 현재
    /// 페이지와 닫는 줌 전환의 기준 항목으로 함께 갱신됩니다.
    public init(
        items: [Item],
        sourceItemID: Item.ID,
        activeItemID: Binding<Item.ID?>,
        zoomTransition: GalleryZoomTransition<Item.ID>? = nil,
        zoomBehavior: ZoomableViewBehavior = .init(),
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        onActiveItemChange: @escaping (Item.ID) -> Void = { _ in },
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) {
        self.items = items
        self.sourceItemID = sourceItemID
        self.zoomTransition = zoomTransition
        self.zoomBehavior = zoomBehavior
        self.contentAspectRatio = contentAspectRatio
        self.onActiveItemChange = onActiveItemChange
        self.content = content
        self.emptyContent = emptyContent
        self._activeItemID = activeItemID
        self._currentPageID = State(
            initialValue: GalleryDetailSelection.resolvedPageID(
                preferredID: activeItemID.wrappedValue ?? sourceItemID,
                currentID: nil,
                activeID: activeItemID.wrappedValue,
                sourceID: sourceItemID,
                itemIDs: items.map(\.id)
            )
        )
    }

    public var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if items.isEmpty {
                emptyContent()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GalleryDetailPager(
                    items: items,
                    currentPageID: $currentPageID,
                    zoomBehavior: zoomBehavior,
                    pagingDisabled: activeItemIsZoomed,
                    onZoomStateChange: updateZoomState,
                    contentAspectRatio: contentAspectRatio,
                    content: content
                )
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
        .galleryZoomTransition(
            fallbackSourceID: sourceItemID,
            using: zoomTransition
        )
        .onAppear {
            resolvePageIDIfNeeded(preferredID: currentPageID)
        }
        .onChange(of: currentPageID) { _, newID in
            selectPage(with: newID)
        }
        .onChange(of: activeItemID) { _, newID in
            resolvePageIDIfNeeded(preferredID: newID)
        }
        .onChange(of: itemIDs) { _, _ in
            removeZoomStateForMissingItems()
            resolvePageIDIfNeeded(preferredID: currentPageID)
        }
    }

    private var itemIDs: [Item.ID] {
        items.map(\.id)
    }

    private var activeItemIsZoomed: Bool {
        guard let currentPageID else { return false }

        return zoomedItemIDs.contains(currentPageID)
    }

    private func resolvePageIDIfNeeded(preferredID: Item.ID?) {
        let resolvedID = GalleryDetailSelection.resolvedPageID(
            preferredID: preferredID,
            currentID: currentPageID,
            activeID: activeItemID,
            sourceID: sourceItemID,
            itemIDs: itemIDs
        )

        guard let resolvedID else {
            currentPageID = nil
            lastNotifiedActiveItemID = nil
            if activeItemID != nil {
                activeItemID = nil
            }
            return
        }

        if currentPageID != resolvedID {
            currentPageID = resolvedID
        }

        if activeItemID != resolvedID {
            activeItemID = resolvedID
        }

        notifyActiveItemChange(resolvedID)
    }

    private func selectPage(with id: Item.ID?) {
        guard let id, itemIDs.contains(id) else { return }

        if activeItemID != id {
            activeItemID = id
        }

        notifyActiveItemChange(id)
    }

    private func notifyActiveItemChange(_ id: Item.ID) {
        guard lastNotifiedActiveItemID != id else { return }

        lastNotifiedActiveItemID = id
        onActiveItemChange(id)
    }

    private func updateZoomState(
        for id: Item.ID,
        isZoomed: Bool
    ) {
        if isZoomed {
            zoomedItemIDs.insert(id)
        } else {
            zoomedItemIDs.remove(id)
        }
    }

    private func removeZoomStateForMissingItems() {
        zoomedItemIDs = zoomedItemIDs.intersection(itemIDs)
    }
}

extension GalleryDetailView where EmptyContent == EmptyView {
    /// 빈 상태 콘텐츠 없이 갤러리 상세 뷰어를 만듭니다.
    public init(
        items: [Item],
        sourceItemID: Item.ID,
        activeItemID: Binding<Item.ID?>,
        zoomTransition: GalleryZoomTransition<Item.ID>? = nil,
        zoomBehavior: ZoomableViewBehavior = .init(),
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        onActiveItemChange: @escaping (Item.ID) -> Void = { _ in },
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.init(
            items: items,
            sourceItemID: sourceItemID,
            activeItemID: activeItemID,
            zoomTransition: zoomTransition,
            zoomBehavior: zoomBehavior,
            contentAspectRatio: contentAspectRatio,
            onActiveItemChange: onActiveItemChange,
            content: content,
            emptyContent: { EmptyView() }
        )
    }
}

struct GalleryDetailSelection<ID: Hashable> {
    static func resolvedPageID(
        preferredID: ID?,
        currentID: ID?,
        activeID: ID?,
        sourceID: ID,
        itemIDs: [ID]
    ) -> ID? {
        guard let firstID = itemIDs.first else { return nil }

        if let preferredID, itemIDs.contains(preferredID) {
            return preferredID
        }

        if let currentID, itemIDs.contains(currentID) {
            return currentID
        }

        if let activeID, itemIDs.contains(activeID) {
            return activeID
        }

        if itemIDs.contains(sourceID) {
            return sourceID
        }

        return firstID
    }
}

private struct GalleryDetailPager<
    Item: Identifiable,
    Content: View
>: View {
    private let items: [Item]
    private let zoomBehavior: ZoomableViewBehavior
    private let pagingDisabled: Bool
    private let onZoomStateChange: (Item.ID, Bool) -> Void
    private let contentAspectRatio: (Item) -> CGFloat?
    private let content: (Item) -> Content

    @Binding private var currentPageID: Item.ID?

    init(
        items: [Item],
        currentPageID: Binding<Item.ID?>,
        zoomBehavior: ZoomableViewBehavior,
        pagingDisabled: Bool,
        onZoomStateChange: @escaping (Item.ID, Bool) -> Void,
        contentAspectRatio: @escaping (Item) -> CGFloat?,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.zoomBehavior = zoomBehavior
        self.pagingDisabled = pagingDisabled
        self.onZoomStateChange = onZoomStateChange
        self.contentAspectRatio = contentAspectRatio
        self.content = content
        self._currentPageID = currentPageID
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: .space0) {
                        ForEach(items) { item in
                            page(for: item)
                                .frame(
                                    width: proxy.size.width,
                                    height: proxy.size.height
                                )
                                .id(item.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
                .scrollPosition(id: $currentPageID)
                .contentMargins(.all, .space0, for: .scrollContent)
                .scrollDisabled(pagingDisabled)
                .background(Color.black)
                .onAppear {
                    scrollToCurrentPage(using: scrollProxy)
                }
                .onChange(of: currentPageID) { _, _ in
                    scrollToCurrentPage(using: scrollProxy)
                }
            }
        }
        .ignoresSafeArea()
    }

    private func scrollToCurrentPage(using proxy: ScrollViewProxy) {
        guard let currentPageID else { return }

        proxy.scrollTo(currentPageID, anchor: .center)
    }

    private func page(for item: Item) -> some View {
        ZoomableView(
            behavior: zoomBehavior,
            contentAspectRatio: contentAspectRatio(item),
            onZoomStateChange: { isZoomed in
                onZoomStateChange(item.id, isZoomed)
            },
            content: {
                content(item)
            }
        )
        .background(Color.black)
    }
}
