import SwiftUI
import UIKit

struct PhotosGalleryPreviewThumbnailService: PhotosGalleryThumbnailServiceProtocol {
    let imageName: String?

    init(imageName: String? = "photo.fill") {
        self.imageName = imageName
    }

    func requestImage(
        for content: PhotosGalleryContent,
        targetSize: CGSize,
        onUpdate: @escaping @Sendable @MainActor (PhotosGalleryThumbnailResult) -> Void
    ) -> PhotosGalleryThumbnailRequest? {
        Task { @MainActor in
            onUpdate(
                PhotosGalleryThumbnailResult(
                    image: imageName.flatMap { UIImage(systemName: $0) },
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
        mediaType: PhotosGalleryMediaType,
        imageName: String? = "photo.fill"
    ) -> some View {
        let viewModel = PhotosGalleryContentViewModel(
            service: PhotosGalleryPreviewThumbnailService(imageName: imageName)
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

#Preview("Thumbnail Placeholder") {
    PhotosGalleryContentViewPreviewFactory.make(
        mediaType: .image,
        imageName: nil
    )
}
