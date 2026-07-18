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
        filter: PhotosGalleryFilter
    ) async -> PhotosGalleryPage {
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
        thumbnailService: any PhotosGalleryThumbnailServiceProtocol = PhotosGalleryPreviewThumbnailService()
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
                selection: .none,
                layout: .compact,
                paginationThreshold: 12,
                zoomTransition: nil,
                scrollPosition: nil,
                contentAspectRatio: { _ in nil },
                accessibilityLabel: nil,
                onTap: { _ in },
                loadingContent: PhotosGallery.Slot {
                    PhotosGalleryDefaultLoadingView()
                },
                unavailableContent: { _ in
                    PhotosGallery.Slot {
                        PhotosGalleryDefaultUnavailableView()
                    }
                },
                emptyContent: PhotosGallery.Slot {
                    PhotosGalleryDefaultEmptyView()
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
                selection: .none,
                layout: GalleryLayout(
                    minimumColumnWidth: 88,
                    maximumColumnWidth: 132,
                    cellAspectRatio: 4 / 3,
                    showsScrollIndicators: true
                ),
                paginationThreshold: 12,
                zoomTransition: nil,
                scrollPosition: nil,
                contentAspectRatio: { _ in nil },
                accessibilityLabel: nil,
                onTap: { _ in },
                loadingContent: PhotosGallery.Slot {
                    PhotosGalleryDefaultLoadingView()
                },
                unavailableContent: { _ in
                    PhotosGallery.Slot {
                        PhotosGalleryDefaultUnavailableView()
                    }
                },
                emptyContent: PhotosGallery.Slot {
                    PhotosGalleryDefaultEmptyView()
                },
                headerContent: PhotosGallery.Slot {
                    Text("Custom Header")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                },
                footerContent: PhotosGallery.Slot {
                    Text("Custom Footer")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            ),
            thumbnailService: PhotosGalleryPreviewThumbnailService()
        )
    }

    static var sampleItems: [PhotosGalleryContent] {
        (1...12).map { index in
            PhotosGalleryContent(
                id: "preview-\(index)",
                mediaType: index.isMultiple(of: 4) ? .video : .image
            )
        }
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
