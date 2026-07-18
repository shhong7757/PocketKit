import Observation
import UIKit

@MainActor
@Observable
final class PhotosGalleryContentViewModel {
    var image: UIImage?

    @ObservationIgnored
    private let service: any PhotosGalleryThumbnailServiceProtocol
    @ObservationIgnored
    private var request: PhotosGalleryThumbnailRequest?
    @ObservationIgnored
    private var requestToken = UUID()

    init(
        service: any PhotosGalleryThumbnailServiceProtocol = PhotosGalleryThumbnailService.live()
    ) {
        self.service = service
    }

    func load(
        content: PhotosGalleryContent,
        targetSize: CGSize
    ) {
        cancel()
        image = nil

        guard targetSize.width > 0, targetSize.height > 0 else { return }

        requestToken = UUID()
        request = service.requestImage(
            for: content,
            targetSize: targetSize
        ) { [weak self] result in
            guard let self,
                  self.requestToken == requestToken,
                  !result.isCancelled,
                  let image = result.image else {
                return
            }

            if result.isDegraded, self.image != nil {
                return
            }

            self.image = image
        }
    }

    func cancel() {
        requestToken = UUID()
        request?.cancel()
        request = nil
    }
}
