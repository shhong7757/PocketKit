import SwiftUI
import UIKit

struct PhotosGalleryPreviewThumbnailService: PhotosGalleryThumbnailServiceProtocol {
    let imageName: String?
    let usesColorPlaceholder: Bool

    init(
        imageName: String? = "photo.fill",
        usesColorPlaceholder: Bool = false
    ) {
        self.imageName = imageName
        self.usesColorPlaceholder = usesColorPlaceholder
    }

    func requestImage(
        for content: PhotosGalleryContent,
        targetSize: CGSize,
        onUpdate: @escaping @Sendable @MainActor (PhotosGalleryThumbnailResult) -> Void
    ) -> PhotosGalleryThumbnailRequest? {
        Task { @MainActor in
            let image = usesColorPlaceholder
                ? makeColorPlaceholder(
                    for: content.id,
                    targetSize: targetSize
                )
                : imageName.flatMap { UIImage(systemName: $0) }

            onUpdate(
                PhotosGalleryThumbnailResult(
                    image: image,
                    isDegraded: false,
                    isCancelled: false
                )
            )
        }

        return nil
    }

    @MainActor
    private func makeColorPlaceholder(
        for contentID: String,
        targetSize: CGSize
    ) -> UIImage {
        let colors: [UIColor] = [
            .systemRed,
            .systemOrange,
            .systemYellow,
            .systemGreen,
            .systemMint,
            .systemTeal,
            .systemCyan,
            .systemBlue,
            .systemIndigo,
            .systemPurple,
            .systemPink,
            .systemBrown,
        ]
        let colorIndex = contentID.utf8.reduce(0) { partialResult, byte in
            (partialResult + Int(byte)) % colors.count
        }
        let size = CGSize(
            width: max(targetSize.width, 1),
            height: max(targetSize.height, 1)
        )

        return UIGraphicsImageRenderer(size: size).image { context in
            context.cgContext.setFillColor(colors[colorIndex].cgColor)
            context.cgContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}

private enum PhotosGalleryContentViewPreviewFactory {
    @MainActor
    static func make(
        id: String,
        mediaType: PhotosGalleryMediaType,
        duration: TimeInterval? = nil,
        isLivePhoto: Bool = false,
        imageName: String? = "photo.fill"
    ) -> some View {
        let viewModel = PhotosGalleryContentViewModel(
            service: PhotosGalleryPreviewThumbnailService(
                imageName: imageName,
                usesColorPlaceholder: imageName != nil
            )
        )

        return PhotosGalleryContentView(
            content: PhotosGalleryContent(
                id: id,
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

                PhotosGalleryContentViewPreviewFactory.make(
                    id: "image",
                    mediaType: .image
                )
            }

            VStack(spacing: 8) {
                Text("Video · 00:01:05")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                PhotosGalleryContentViewPreviewFactory.make(
                    id: "video",
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
                    id: "live-photo",
                    mediaType: .image,
                    isLivePhoto: true
                )
            }

            VStack(spacing: 8) {
                Text("Placeholder")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                PhotosGalleryContentViewPreviewFactory.make(
                    id: "placeholder",
                    mediaType: .image,
                    imageName: nil
                )
            }
        }
    }
    .padding()
}
