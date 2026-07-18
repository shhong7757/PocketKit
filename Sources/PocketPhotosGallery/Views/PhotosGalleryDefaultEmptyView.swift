import SwiftUI

/// The default read-only empty state for ``PhotosGallery``.
@MainActor
public struct PhotosGalleryDefaultEmptyView: View {
    public init() {}

    public var body: some View {
        ContentUnavailableView {
            Label(
                String(localized: "mediaGallery.emptyTitle", bundle: .module),
                systemImage: "photo.on.rectangle.angled"
            )
        } description: {
            Text(
                String(
                    localized: "mediaGallery.emptyDescription",
                    bundle: .module
                )
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
    }
}
