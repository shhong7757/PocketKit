import SwiftUI

/// The default read-only unavailable state for ``PhotosGallery``.
@MainActor
public struct PhotosGalleryDefaultUnavailableView: View {
    public init() {}

    public var body: some View {
        ContentUnavailableView {
            Label(
                String(localized: "mediaGallery.accessRequiredTitle", bundle: .module),
                systemImage: "lock.slash"
            )
        } description: {
            Text(
                String(
                    localized: "mediaGallery.accessRequiredDescription",
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
