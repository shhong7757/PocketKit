import SwiftUI

struct MediaGalleryNavigationDetailDestination<
    Item: Identifiable,
    DetailContent: View,
    DetailToolbar: ToolbarContent
>: View {
    private let items: [Item]
    private let sourceItemID: Item.ID
    private let zoomBehavior: ZoomableViewBehavior
    private let transitionNamespace: Namespace.ID
    private let contentAspectRatio: (Item) -> CGFloat?
    private let detailContent: (Item) -> DetailContent
    private let detailToolbarContent: (Item) -> DetailToolbar

    @Binding private var selection: Item?
    @State private var currentSelection: Item?

    init(
        items: [Item],
        selection: Binding<Item?>,
        sourceItemID: Item.ID,
        zoomBehavior: ZoomableViewBehavior,
        transitionNamespace: Namespace.ID,
        contentAspectRatio: @escaping (Item) -> CGFloat?,
        @ViewBuilder detailContent: @escaping (Item) -> DetailContent,
        @ToolbarContentBuilder detailToolbarContent: @escaping (Item) -> DetailToolbar
    ) {
        self.items = items
        self.sourceItemID = sourceItemID
        self.zoomBehavior = zoomBehavior
        self.transitionNamespace = transitionNamespace
        self.contentAspectRatio = contentAspectRatio
        self.detailContent = detailContent
        self.detailToolbarContent = detailToolbarContent
        self._selection = selection
        self._currentSelection = State(
            initialValue: items.mediaGalleryItem(withID: sourceItemID)
                ?? items.mediaGalleryResolvedSelection(selection.wrappedValue)
        )
    }

    var body: some View {
        MediaGalleryDetailView(
            items: items,
            selection: $currentSelection,
            zoomBehavior: zoomBehavior,
            contentAspectRatio: contentAspectRatio,
            mediaContent: detailContent
        )
        .mediaGalleryNavigationZoomTransition(
            sourceID: transitionSourceID,
            in: transitionNamespace
        )
        .toolbar {
            if let selectedItem {
                detailToolbarContent(selectedItem)
            }
        }
        .onAppear(perform: syncSelection)
        .onChange(of: currentSelection?.id) { _, _ in
            syncSelection()
        }
        .onChange(of: itemIDs) { _, _ in
            syncSelection()
        }
    }

    private var itemIDs: [Item.ID] {
        items.mediaGalleryItemIDs
    }

    private var selectedItem: Item? {
        if let id = currentSelection?.id {
            if let item = item(withID: id) {
                return item
            }
        }

        return item(withID: sourceItemID)
            ?? items.mediaGalleryResolvedSelection(selection)
    }

    private var transitionSourceID: Item.ID {
        selectedItem?.id ?? sourceItemID
    }

    private func item(withID id: Item.ID?) -> Item? {
        items.mediaGalleryItem(withID: id)
    }

    private func syncSelection() {
        selection = selectedItem
    }
}

extension View {
    @ViewBuilder
    fileprivate func mediaGalleryNavigationZoomTransition(
        sourceID: some Hashable,
        in namespace: Namespace.ID
    ) -> some View {
        #if os(iOS)
            navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        #else
            self
        #endif
    }
}
