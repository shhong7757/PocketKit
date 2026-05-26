import SwiftUI

/// 미디어 갤러리 항목을 페이지 형태로 보여주는 상세 뷰어입니다.
struct MediaGalleryDetailView<Item: Identifiable, MediaContent: View>: View {
    private let items: [Item]
    private let zoomBehavior: ZoomableViewBehavior
    private let contentAspectRatio: (Item) -> CGFloat?
    private let mediaContent: (Item) -> MediaContent
    private let onSelectionChange: (Item, Int) -> Void

    @Binding private var selection: Item?
    @State private var currentPageID: Item.ID?
    @State private var lastNotifiedSelectionID: Item.ID?
    @State private var lastNotifiedSelectionIndex: Int?
    @State private var zoomedItemIDs: Set<Item.ID> = []

    /// 커스텀 미디어 콘텐츠를 사용하는 상세 뷰어를 만듭니다.
    ///
    /// `selection`이 `nil`이거나 `items` 안에 없으면 첫 번째 항목으로 바인딩을
    /// 보정합니다. `items`가 비어 있으면 바인딩을 `nil`로 보정합니다.
    init(
        items: [Item],
        selection: Binding<Item?>,
        zoomBehavior: ZoomableViewBehavior = .init(isEnabled: false),
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        @ViewBuilder mediaContent: @escaping (Item) -> MediaContent,
        onSelectionChange: @escaping (Item, Int) -> Void = { _, _ in }
    ) {
        self.items = items
        self.zoomBehavior = zoomBehavior
        self.contentAspectRatio = contentAspectRatio
        self._selection = selection
        self._currentPageID = State(
            initialValue: items.mediaGalleryResolvedSelection(selection.wrappedValue)?.id
        )
        self.mediaContent = mediaContent
        self.onSelectionChange = onSelectionChange
    }

    @available(
        *,
        deprecated,
        renamed:
            "init(items:selection:zoomBehavior:contentAspectRatio:mediaContent:onSelectionChange:)"
    )
    init(
        items: [Item],
        selection: Binding<Item?>,
        interaction: ZoomableViewBehavior,
        contentAspectRatio: @escaping (Item) -> CGFloat? = { _ in nil },
        @ViewBuilder mediaContent: @escaping (Item) -> MediaContent,
        onSelectionChange: @escaping (Item, Int) -> Void = { _, _ in }
    ) {
        self.init(
            items: items,
            selection: selection,
            zoomBehavior: interaction,
            contentAspectRatio: contentAspectRatio,
            mediaContent: mediaContent,
            onSelectionChange: onSelectionChange
        )
    }

    var body: some View {
        MediaGalleryDetailPager(
            items: items,
            currentPageID: $currentPageID,
            zoomBehavior: zoomBehavior,
            pagingDisabled: selectedItemIsZoomed,
            onZoomStateChange: updateZoomState,
            contentAspectRatio: contentAspectRatio,
            content: mediaContent
        )
        .background(Color.black)
        .ignoresSafeArea()
        .onAppear {
            resolveSelectionIfNeeded()
        }
        .onChange(of: currentPageID) { _, newID in
            selectPage(with: newID)
        }
        .onChange(of: selection?.id) { _, _ in
            resolveSelectionIfNeeded()
        }
        .onChange(of: itemIDs) { _, _ in
            removeZoomStateForMissingItems()
            resolveSelectionIfNeeded()
        }
    }

    private var selectedItem: Item? {
        items.mediaGalleryItem(withID: currentPageID)
            ?? items.mediaGalleryResolvedSelection(selection)
    }

    private var itemIDs: [Item.ID] {
        items.mediaGalleryItemIDs
    }

    private var selectedItemIsZoomed: Bool {
        guard let selectedItem else { return false }

        return zoomedItemIDs.contains(selectedItem.id)
    }

    private func resolveSelectionIfNeeded() {
        let resolvedSelection = items.mediaGalleryResolvedSelection(selection)

        guard let resolvedSelection else {
            currentPageID = nil
            lastNotifiedSelectionID = nil
            lastNotifiedSelectionIndex = nil
            if selection != nil {
                selection = nil
            }
            return
        }

        if selection?.id != resolvedSelection.id {
            selection = resolvedSelection
        }

        if currentPageID != resolvedSelection.id {
            currentPageID = resolvedSelection.id
        }

        notifySelectionChange(for: resolvedSelection)
    }

    private func selectPage(with id: Item.ID?) {
        guard let item = items.mediaGalleryItem(withID: id) else { return }

        if selection?.id != item.id {
            selection = item
        }

        notifySelectionChange(for: item)
    }

    private func notifySelectionChange(for selection: Item?) {
        guard let selection,
            let index = items.mediaGalleryIndex(ofID: selection.id)
        else {
            return
        }
        guard lastNotifiedSelectionID != selection.id || lastNotifiedSelectionIndex != index else {
            return
        }

        lastNotifiedSelectionID = selection.id
        lastNotifiedSelectionIndex = index
        onSelectionChange(items[index], index)
    }

    private func updateZoomState(
        for id: Item.ID,
        isZoomed: Bool
    ) {
        if isZoomed {
            guard !zoomedItemIDs.contains(id) else { return }
            zoomedItemIDs.insert(id)
        } else {
            guard zoomedItemIDs.contains(id) else { return }
            zoomedItemIDs.remove(id)
        }
    }

    private func removeZoomStateForMissingItems() {
        let currentItemIDs = Set(itemIDs)
        zoomedItemIDs = zoomedItemIDs.intersection(currentItemIDs)
    }
}

private struct MediaGalleryDetailPager<Item: Identifiable, Content: View>: View {
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
                    LazyHStack(spacing: PocketUISpacing.space0) {
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
                .contentMargins(.all, PocketUISpacing.space0, for: .scrollContent)
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
