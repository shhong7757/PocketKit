import Photos

@MainActor
protocol PhotosGalleryAuthorizationServiceProtocol {
    func currentAuthorizationStatus() -> PhotosGalleryAccessStatus
    func requestAuthorization() async -> PhotosGalleryAccessStatus
}

@MainActor
struct PhotosGalleryAuthorizationService: PhotosGalleryAuthorizationServiceProtocol {
    static func live() -> PhotosGalleryAuthorizationService {
        PhotosGalleryAuthorizationService()
    }

    func currentAuthorizationStatus() -> PhotosGalleryAccessStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite).photosGalleryAccessStatus
    }

    func requestAuthorization() async -> PhotosGalleryAccessStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite).photosGalleryAccessStatus
    }
}

private extension PHAuthorizationStatus {
    var photosGalleryAccessStatus: PhotosGalleryAccessStatus {
        switch self {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .restricted
        }
    }
}
