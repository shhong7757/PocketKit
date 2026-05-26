import SwiftUI

struct MediaGalleryNavigationRoute<ID: Hashable>: Hashable {
    let itemID: ID
}

struct MediaGalleryNavigationGrid<
    Item: Identifiable,
    Thumbnail: View,
    OverlayContent: View,
    EmptyContent: View
>: View {
    private let items: [Item]
    private let contentDisplayMode: MediaGalleryContentDisplayMode
    private let layout: MediaGalleryLayout
    private let transitionNamespace: Namespace.ID
    private let contentAspectRatio: (Item) -> CGFloat?
    private let accessibilityLabel: (Item) -> String
    private let loadMoreBehavior: MediaGalleryLoadMoreBehavior
    private let thumbnailContent: (Item) -> Thumbnail
    private let overlayContent: (Item) -> OverlayContent
    private let emptyStateContent: () -> EmptyContent

    @Binding private var selection: Item?
    @State private var loadMoreTriggerState =
        LastItemLoadMoreTriggerState<Item.ID>()

    init(
        items: [Item],
        selection: Binding<Item?>,
        contentDisplayMode: MediaGalleryContentDisplayMode,
        layout: MediaGalleryLayout,
        transitionNamespace: Namespace.ID,
        contentAspectRatio: @escaping (Item) -> CGFloat?,
        accessibilityLabel: @escaping (Item) -> String,
        loadMoreBehavior: MediaGalleryLoadMoreBehavior,
        @ViewBuilder thumbnailContent: @escaping (Item) -> Thumbnail,
        @ViewBuilder overlayContent: @escaping (Item) -> OverlayContent,
        @ViewBuilder emptyStateContent: @escaping () -> EmptyContent
    ) {
        self.items = items
        self.contentDisplayMode = contentDisplayMode
        self.layout = layout
        self.transitionNamespace = transitionNamespace
        self.contentAspectRatio = contentAspectRatio
        self.accessibilityLabel = accessibilityLabel
        self.loadMoreBehavior = loadMoreBehavior
        self.thumbnailContent = thumbnailContent
        self.overlayContent = overlayContent
        self.emptyStateContent = emptyStateContent
        self._selection = selection
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                if items.isEmpty {
                    emptyStateContent()
                        .frame(maxWidth: .infinity)
                        .padding(layout.resolvedSpacing)
                } else {
                    LazyVGrid(
                        columns: layout.columns,
                        spacing: layout.resolvedSpacing
                    ) {
                        ForEach(items) { item in
                            navigationLink(item)
                        }
                    }
                    .padding(layout.resolvedSpacing)

                    if loadMoreBehavior.isLoadingMore {
                        loadMoreProgressView()
                    }
                }
            }
            .scrollIndicators(layout.showsScrollIndicators ? .visible : .hidden)
            .onAppear {
                scrollToSelectedItem(using: scrollProxy)
            }
            .onChange(of: selectedItemID) { _, _ in
                scrollToSelectedItem(using: scrollProxy)
            }
            .onChange(of: itemIDs) { oldItemIDs, newItemIDs in
                loadMoreTriggerState.itemsDidChange(to: newItemIDs)
                loadMoreForVisibleLastItemIfNeeded()
                scrollToSelectedItemIfNewlyAvailable(
                    previousItemIDs: oldItemIDs,
                    currentItemIDs: newItemIDs,
                    using: scrollProxy
                )
            }
            .onChange(of: loadMoreBehavior.canLoadMore) { oldValue, newValue in
                guard !oldValue && newValue else { return }
                loadMoreTriggerState.allowRetryForCurrentItems()
                loadMoreForVisibleLastItemIfNeeded()
            }
        }
    }

    private var itemIDs: [Item.ID] {
        items.mediaGalleryItemIDs
    }

    private var selectedItemID: Item.ID? {
        selection?.id
    }

    private func navigationLink(_ item: Item) -> some View {
        NavigationLink(
            value: MediaGalleryNavigationRoute(itemID: item.id)
        ) {
            MediaGalleryGridCell(
                contentDisplayMode: contentDisplayMode,
                cellAspectRatio: layout.resolvedCellAspectRatio,
                contentAspectRatio: contentAspectRatio(item),
                accessibilityLabel: accessibilityLabel(item),
                thumbnail: thumbnailContent(item),
                overlayContent: overlayContent(item)
            )
            .matchedTransitionSource(id: item.id, in: transitionNamespace)
        }
        .id(item.id)
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture().onEnded {
                selection = item
            }
        )
        .onAppear {
            handleItemAppear(item)
        }
        .onDisappear {
            loadMoreTriggerState.itemDidDisappear(item.id)
        }
    }

    private func handleItemAppear(_ item: Item) {
        if loadMoreTriggerState.itemDidAppear(
            item.id,
            itemIDs: itemIDs,
            canLoadMore: loadMoreBehavior.canLoadMore
        ) {
            loadMoreBehavior.loadMore()
        }
    }

    private func loadMoreForVisibleLastItemIfNeeded() {
        if loadMoreTriggerState.triggerForVisibleLastItemIfNeeded(
            itemIDs: itemIDs,
            canLoadMore: loadMoreBehavior.canLoadMore
        ) {
            loadMoreBehavior.loadMore()
        }
    }

    private func scrollToSelectedItem(using proxy: ScrollViewProxy) {
        guard let selectedItemID,
            items.mediaGalleryContainsItem(withID: selectedItemID)
        else {
            return
        }

        proxy.scrollTo(selectedItemID, anchor: .center)
    }

    private func scrollToSelectedItemIfNewlyAvailable(
        previousItemIDs: [Item.ID],
        currentItemIDs: [Item.ID],
        using proxy: ScrollViewProxy
    ) {
        guard let selectedItemID,
            !previousItemIDs.contains(selectedItemID),
            currentItemIDs.contains(selectedItemID)
        else {
            return
        }

        proxy.scrollTo(selectedItemID, anchor: .center)
    }

    private func loadMoreProgressView() -> some View {
        ProgressView()
            .controlSize(.regular)
            .frame(maxWidth: .infinity)
            .padding(
                .vertical,
                max(PocketUISpacing.space3, layout.resolvedSpacing * 2)
            )
            .accessibilityLabel(Text("Loading more media"))
    }
}

private struct MediaGalleryGridCell<
    Thumbnail: View,
    OverlayContent: View
>: View {
    private enum Metrics {
        static var backgroundOpacity: Double { 0.1 }
        static var borderOpacity: Double { 0.06 }
        static var borderWidth: CGFloat { 1 }
    }

    let contentDisplayMode: MediaGalleryContentDisplayMode
    let cellAspectRatio: CGFloat
    let contentAspectRatio: CGFloat?
    let accessibilityLabel: String
    let thumbnail: Thumbnail
    let overlayContent: OverlayContent

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let contentSize = contentDisplayMode.contentSize(
                    aspectRatio: contentAspectRatio,
                    in: proxy.size
                )

                thumbnail
                    .frame(width: contentSize.width, height: contentSize.height)
                    .clipped()
                    .position(
                        x: proxy.size.width / 2,
                        y: proxy.size.height / 2
                    )
            }
        }
        .aspectRatio(cellAspectRatio, contentMode: .fit)
        .background(Color.secondary.opacity(Metrics.backgroundOpacity))
        .clipShape(Rectangle())
        .overlay {
            Rectangle()
                .stroke(
                    Color.primary.opacity(Metrics.borderOpacity),
                    lineWidth: Metrics.borderWidth
                )
        }
        .overlay(alignment: .bottomLeading) {
            overlayContent
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
    }
}

struct LastItemLoadMoreTriggerState<ID: Hashable> {
    private var visibleIDs: Set<ID> = []
    private var triggeredLastItem: TriggeredLastItem?

    mutating func itemDidAppear(
        _ id: ID,
        itemIDs: [ID],
        canLoadMore: Bool
    ) -> Bool {
        visibleIDs.insert(id)
        return recordLoadMoreTriggerIfNeeded(
            for: id,
            itemIDs: itemIDs,
            canLoadMore: canLoadMore
        )
    }

    mutating func itemDidDisappear(_ id: ID) {
        visibleIDs.remove(id)
    }

    mutating func itemsDidChange(to itemIDs: [ID]) {
        visibleIDs = visibleIDs.intersection(itemIDs)
        triggeredLastItem = nil
    }

    mutating func allowRetryForCurrentItems() {
        triggeredLastItem = nil
    }

    mutating func triggerForVisibleLastItemIfNeeded(
        itemIDs: [ID],
        canLoadMore: Bool
    ) -> Bool {
        guard let lastID = itemIDs.last,
            visibleIDs.contains(lastID)
        else {
            return false
        }

        return recordLoadMoreTriggerIfNeeded(
            for: lastID,
            itemIDs: itemIDs,
            canLoadMore: canLoadMore
        )
    }

    private mutating func recordLoadMoreTriggerIfNeeded(
        for id: ID,
        itemIDs: [ID],
        canLoadMore: Bool
    ) -> Bool {
        guard canLoadMore else { return false }
        guard id == itemIDs.last else { return false }

        let nextTrigger = TriggeredLastItem(
            id: id,
            itemCount: itemIDs.count
        )
        guard triggeredLastItem != nextTrigger else { return false }

        triggeredLastItem = nextTrigger
        return true
    }

    private struct TriggeredLastItem: Equatable {
        let id: ID
        let itemCount: Int
    }
}
