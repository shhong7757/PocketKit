import PocketUI
import SwiftUI

private struct PreviewPhotosGalleryService: PhotosGalleryAuthorizationServiceProtocol,
                                             PhotosGalleryPaginationServiceProtocol {
    let accessStatus: PhotosGalleryAccessStatus
    let firstPage: PhotosGalleryPage

    func currentAuthorizationStatus() -> PhotosGalleryAccessStatus {
        accessStatus
    }

    func requestAuthorization() async -> PhotosGalleryAccessStatus {
        accessStatus
    }

    func fetch(
        offset: Int,
        limit: Int,
        filter: PhotosGalleryFilter,
        includeLivePhotos: Bool
    ) async throws -> PhotosGalleryPage {
        guard offset == 0 else {
            return PhotosGalleryPage(items: [], offset: offset, hasNextPage: false)
        }

        return firstPage
    }

}

@MainActor
private enum PhotosGalleryPreviewFactory {
    static func make(
        accessStatus: PhotosGalleryAccessStatus,
        items: [PhotosGalleryContent] = [],
        thumbnailService: any PhotosGalleryThumbnailServiceProtocol = PhotosGalleryPreviewThumbnailService(
            usesColorPlaceholder: true
        )
    ) -> some View {
        let service = PreviewPhotosGalleryService(
            accessStatus: accessStatus,
            firstPage: PhotosGalleryPage(
                items: items,
                offset: items.isEmpty ? 0 : items.count,
                hasNextPage: false
            )
        )
        let viewModel = PhotosGalleryViewModel(
            filter: .all,
            authorizationUseCase: PhotosGalleryAuthorizationUseCase(service: service),
            pagingUseCase: PhotosGalleryPagingUseCase(service: service)
        )

        return PhotosGallery(
            vm: viewModel,
            configuration: PhotosGallery.Configuration(
                filter: .all,
                includeLivePhotos: false,
                selection: .none,
                layout: .compact,
                zoomTransition: nil,
                scrollPosition: nil,
                contentAspectRatio: { _ in nil },
                accessibility: PhotosGalleryPreviewFactory.accessibility,
                onTap: { _ in },
                onError: nil,
                loadingContent: PhotosGallery.Slot {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                },
                unavailableContent: { _ in
                    PhotosGallery.Slot {
                        ContentUnavailableView(
                            "Photo Access Required",
                            systemImage: "lock.slash"
                        )
                    }
                },
                emptyContent: PhotosGallery.Slot {
                    ContentUnavailableView(
                        "No Photos Yet",
                        systemImage: "photo.on.rectangle.angled"
                    )
                },
                headerContent: nil,
                footerContent: nil
            ),
            thumbnailService: thumbnailService
        )
    }

    static func makeCustomized() -> some View {
        let service = PreviewPhotosGalleryService(
            accessStatus: .authorized,
            firstPage: PhotosGalleryPage(
                items: sampleItems,
                offset: sampleItems.count,
                hasNextPage: false
            )
        )
        let viewModel = PhotosGalleryViewModel(
            filter: .all,
            authorizationUseCase: PhotosGalleryAuthorizationUseCase(service: service),
            pagingUseCase: PhotosGalleryPagingUseCase(service: service)
        )

        return PhotosGallery(
            vm: viewModel,
            configuration: PhotosGallery.Configuration(
                filter: .all,
                includeLivePhotos: false,
                selection: .none,
                layout: GalleryLayout(
                    minimumColumnWidth: 88,
                    maximumColumnWidth: 132,
                    cellAspectRatio: 4 / 3,
                    showsScrollIndicators: true
                ),
                zoomTransition: nil,
                scrollPosition: nil,
                contentAspectRatio: { _ in nil },
                accessibility: PhotosGalleryPreviewFactory.accessibility,
                onTap: { _ in },
                onError: nil,
                loadingContent: PhotosGallery.Slot {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                },
                unavailableContent: { _ in
                    PhotosGallery.Slot {
                        ContentUnavailableView(
                            "Photo Access Required",
                            systemImage: "lock.slash"
                        )
                    }
                },
                emptyContent: PhotosGallery.Slot {
                    ContentUnavailableView(
                        "No Photos Yet",
                        systemImage: "photo.on.rectangle.angled"
                    )
                },
                headerContent: PhotosGallery.Slot { context in
                    Text("Custom Header · \(context.contentCount)")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                },
                footerContent: PhotosGallery.Slot { context in
                    Text(
                        context.isFetchingNextPage
                            ? "Loading more..."
                            : "Custom Footer"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            ),
            thumbnailService: PhotosGalleryPreviewThumbnailService(
                usesColorPlaceholder: true
            )
        )
    }

    static var sampleItems: [PhotosGalleryContent] {
        (1...12).map { index in
            let isVideo = index.isMultiple(of: 4)

            return PhotosGalleryContent(
                id: "preview-\(index)",
                mediaType: isVideo ? .video : .image,
                duration: isVideo ? 65 : nil,
                isLivePhoto: !isVideo && index.isMultiple(of: 3)
            )
        }
    }

    static func accessibility(
        for content: PhotosGalleryContent
    ) -> PhotosGalleryAccessibility {
        var values: [String] = []

        if content.isLivePhoto {
            values.append("Live Photo")
        }

        if content.mediaType == .video,
           let duration = content.duration {
            values.append(formattedDuration(duration))
        }

        return PhotosGalleryAccessibility(
            label: content.mediaType == .video ? "Video" : "Photo",
            value: values.isEmpty ? nil : values.joined(separator: ", ")
        )
    }

    private static func formattedDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = max(Int(duration), 0)
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        return String(
            format: "%02d:%02d:%02d",
            locale: Locale(identifier: "en_US_POSIX"),
            hours,
            minutes,
            seconds
        )
    }
}

#Preview("Photos Gallery Loading") {
    PhotosGalleryPreviewFactory.make(accessStatus: .notDetermined)
}

#Preview("Photos Gallery Access Disabled") {
    PhotosGalleryPreviewFactory.make(accessStatus: .denied)
}

#Preview("Photos Gallery Empty") {
    PhotosGalleryPreviewFactory.make(accessStatus: .authorized)
}

#Preview("Photos Gallery Loaded") {
    PhotosGalleryPreviewFactory.make(
        accessStatus: .authorized,
        items: PhotosGalleryPreviewFactory.sampleItems
    )
}

#Preview("Photos Gallery Customized") {
    PhotosGalleryPreviewFactory.makeCustomized()
}
