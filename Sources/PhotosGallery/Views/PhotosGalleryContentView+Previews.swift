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
        duration: TimeInterval? = nil,
        isLivePhoto: Bool = false,
        imageName: String? = "photo.fill"
    ) -> some View {
        let viewModel = PhotosGalleryContentViewModel(
            service: PhotosGalleryPreviewThumbnailService(imageName: imageName)
        )

        return PhotosGalleryContentView(
            content: PhotosGalleryContent(
                id: "preview",
                mediaType: mediaType,
                duration: duration,
                isLivePhoto: isLivePhoto
            ),
            vm: viewModel
        )
        .frame(width: 120, height: 120)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Image")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                PhotosGalleryContentViewPreviewFactory.make(mediaType: .image)
            }

            VStack(spacing: 8) {
                Text("Video · 00:01:05")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                PhotosGalleryContentViewPreviewFactory.make(
                    mediaType: .video,
                    duration: 65
                )
            }
        }

        HStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Live Photo")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                PhotosGalleryContentViewPreviewFactory.make(
                    mediaType: .image,
                    isLivePhoto: true
                )
            }

            VStack(spacing: 8) {
                Text("Placeholder")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                PhotosGalleryContentViewPreviewFactory.make(
                    mediaType: .image,
                    imageName: nil
                )
            }
        }
    }
    .padding()
}
