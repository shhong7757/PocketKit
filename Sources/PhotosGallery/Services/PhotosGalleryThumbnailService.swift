import Foundation
import Photos
import UIKit

@MainActor
struct PhotosGalleryThumbnailResult {
    let image: UIImage?
    let isDegraded: Bool
    let isCancelled: Bool
}

final class PhotosGalleryThumbnailRequest: @unchecked Sendable {
    private let imageManager: PHCachingImageManager
    private let lock = NSLock()
    private var task: Task<Void, Never>?
    private var requestID = PHInvalidImageRequestID
    private var isCancelled = false

    init(imageManager: PHCachingImageManager) {
        self.imageManager = imageManager
    }

    func set(task: Task<Void, Never>) {
        lock.lock()
        let shouldCancel = isCancelled
        if !shouldCancel {
            self.task = task
        }
        lock.unlock()

        if shouldCancel {
            task.cancel()
        }
    }

    func set(requestID: PHImageRequestID) {
        lock.lock()
        let shouldCancel = isCancelled
        if !shouldCancel {
            self.requestID = requestID
        }
        lock.unlock()

        if shouldCancel {
            imageManager.cancelImageRequest(requestID)
        }
    }

    func cancel() {
        lock.lock()
        guard !isCancelled else {
            lock.unlock()
            return
        }

        isCancelled = true
        let task = task
        let requestID = requestID
        self.task = nil
        self.requestID = PHInvalidImageRequestID
        lock.unlock()

        task?.cancel()
        guard requestID != PHInvalidImageRequestID else { return }
        imageManager.cancelImageRequest(requestID)
    }
}

protocol PhotosGalleryThumbnailServiceProtocol: Sendable {
    func requestImage(
        for content: PhotosGalleryContent,
        targetSize: CGSize,
        onUpdate: @escaping @Sendable @MainActor (PhotosGalleryThumbnailResult) -> Void
    ) -> PhotosGalleryThumbnailRequest?
}

struct PhotosGalleryThumbnailService: PhotosGalleryThumbnailServiceProtocol {
    private static let imageManager = PHCachingImageManager()

    static func live() -> PhotosGalleryThumbnailService {
        PhotosGalleryThumbnailService()
    }

    func requestImage(
        for content: PhotosGalleryContent,
        targetSize: CGSize,
        onUpdate: @escaping @Sendable @MainActor (PhotosGalleryThumbnailResult) -> Void
    ) -> PhotosGalleryThumbnailRequest? {
        let request = PhotosGalleryThumbnailRequest(imageManager: Self.imageManager)
        let task = Task.detached(priority: .userInitiated) {
            guard !Task.isCancelled,
                  let asset = PHAsset.fetchAssets(
                      withLocalIdentifiers: [content.id],
                      options: nil
                  ).firstObject else {
                return
            }

            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true

            Self.imageManager.startCachingImages(
                for: [asset],
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            )

            let requestID = Self.imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) == true
                let isCancelled = (info?[PHImageCancelledKey] as? Bool) == true

                Task { @MainActor in
                    onUpdate(
                        PhotosGalleryThumbnailResult(
                            image: image,
                            isDegraded: isDegraded,
                            isCancelled: isCancelled
                        )
                    )
                }
            }

            request.set(requestID: requestID)
        }
        request.set(task: task)
        return request
    }
}
