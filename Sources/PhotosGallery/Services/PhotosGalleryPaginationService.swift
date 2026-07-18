import Photos

protocol PhotosGalleryPaginationServiceProtocol: Sendable {
    func fetch(
        offset: Int,
        limit: Int,
        filter: PhotosGalleryFilter
    ) async -> PhotosGalleryPage
}

struct PhotosGalleryPaginationService: PhotosGalleryPaginationServiceProtocol {
    static func live() -> PhotosGalleryPaginationService {
        PhotosGalleryPaginationService()
    }

    func fetch(
        offset: Int,
        limit: Int,
        filter: PhotosGalleryFilter
    ) async -> PhotosGalleryPage {
        guard !Task.isCancelled else {
            return PhotosGalleryPage(items: [], offset: offset, hasNextPage: false)
        }

        let fetchResult = fetchResult(for: filter)
        let totalCount = fetchResult.count
        let startIndex = min(max(offset, 0), totalCount)
        let endIndex = min(startIndex + max(limit, 0), totalCount)

        guard startIndex < endIndex else {
            return PhotosGalleryPage(
                items: [],
                offset: startIndex,
                hasNextPage: startIndex < totalCount
            )
        }

        var items: [PhotosGalleryContent] = []
        items.reserveCapacity(endIndex - startIndex)

        for index in startIndex..<endIndex {
            guard !Task.isCancelled else {
                return PhotosGalleryPage(
                    items: [],
                    offset: startIndex,
                    hasNextPage: startIndex < totalCount
                )
            }

            let asset = fetchResult.object(at: index)
            guard let mediaType = PhotosGalleryMediaType(asset.mediaType) else {
                continue
            }

            items.append(
                PhotosGalleryContent(
                    id: asset.localIdentifier,
                    mediaType: mediaType
                )
            )
        }

        return PhotosGalleryPage(
            items: items,
            offset: endIndex,
            hasNextPage: endIndex < totalCount
        )
    }

    private func fetchResult(for filter: PhotosGalleryFilter) -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        options.includeAssetSourceTypes = [
            .typeUserLibrary,
            .typeCloudShared,
            .typeiTunesSynced,
        ]

        switch filter {
        case .images:
            return PHAsset.fetchAssets(with: .image, options: options)
        case .videos:
            return PHAsset.fetchAssets(with: .video, options: options)
        case .all:
            options.predicate = NSPredicate(
                format: "mediaType == %d OR mediaType == %d",
                PHAssetMediaType.image.rawValue,
                PHAssetMediaType.video.rawValue
            )
            return PHAsset.fetchAssets(with: options)
        }
    }
}

private extension PhotosGalleryMediaType {
    init?(_ photoKitType: PHAssetMediaType) {
        switch photoKitType {
        case .image:
            self = .image
        case .video:
            self = .video
        default:
            return nil
        }
    }
}
