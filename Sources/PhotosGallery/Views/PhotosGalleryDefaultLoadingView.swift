import SwiftUI

/// The default read-only loading state for ``PhotosGallery``.
@MainActor
public struct PhotosGalleryDefaultLoadingView: View {
    public init() {}

    public var body: some View {
        ProgressView()
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .center
            )
    }
}
