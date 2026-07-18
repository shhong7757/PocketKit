import SwiftUI
import UIKit

struct PhotosGalleryPreviewThumbnailService: PhotosGalleryThumbnailServiceProtocol {
    func requestImage(
        for content: PhotosGalleryContent,
        targetSize: CGSize,
        onUpdate: @escaping @Sendable @MainActor (PhotosGalleryThumbnailResult) -> Void
    ) -> PhotosGalleryThumbnailRequest? {
        Task { @MainActor in
            onUpdate(
                PhotosGalleryThumbnailResult(
                    image: UIImage(systemName: "photo.fill"),
                    isDegraded: false,
                    isCancelled: false
                )
            )
        }

        return nil
    }
}

private enum PhotosGalleryContentViewPreviewFactory {
    @MainActor
    static func make(
        mediaType: PhotosGalleryMediaType
    ) -> some View {
        let viewModel = PhotosGalleryContentViewModel(
            service: PhotosGalleryPreviewThumbnailService()
        )

        return PhotosGalleryContentView(
            content: PhotosGalleryContent(
                id: "preview",
                mediaType: mediaType
            ),
            vm: viewModel
        )
        .frame(width: 120, height: 120)
    }
}

#Preview("Image Content") {
    PhotosGalleryContentViewPreviewFactory.make(mediaType: .image)
}

#Preview("Video Content") {
    PhotosGalleryContentViewPreviewFactory.make(mediaType: .video)
}
