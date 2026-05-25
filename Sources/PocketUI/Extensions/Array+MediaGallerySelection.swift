extension Array where Element: Identifiable {
    var mediaGalleryItemIDs: [Element.ID] {
        map(\.id)
    }

    func mediaGalleryItem(withID id: Element.ID?) -> Element? {
        guard let id else { return nil }

        return first { $0.id == id }
    }

    func mediaGalleryContainsItem(withID id: Element.ID?) -> Bool {
        guard let id else { return false }

        return contains { $0.id == id }
    }

    func mediaGalleryIndex(ofID id: Element.ID?) -> Int? {
        guard let id else { return nil }

        return firstIndex { $0.id == id }
    }

    func mediaGalleryResolvedSelection(
        _ selection: Element?
    ) -> Element? {
        guard !isEmpty else { return nil }
        guard let selection else { return self[0] }

        return mediaGalleryItem(withID: selection.id) ?? self[0]
    }

    func mediaGalleryResolvedSelectionIndex(
        of selection: Element?
    ) -> Int? {
        guard let resolvedSelection = mediaGalleryResolvedSelection(selection)
        else {
            return nil
        }

        return mediaGalleryIndex(ofID: resolvedSelection.id)
    }
}
