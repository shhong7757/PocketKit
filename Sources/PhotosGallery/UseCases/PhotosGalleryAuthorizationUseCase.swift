@MainActor
struct PhotosGalleryAuthorizationUseCase {
    private let service: any PhotosGalleryAuthorizationServiceProtocol

    init(service: any PhotosGalleryAuthorizationServiceProtocol) {
        self.service = service
    }

    func status() -> PhotosGalleryAccessStatus {
        service.currentAuthorizationStatus()
    }

    func requestAccessIfNeeded() async -> PhotosGalleryAccessStatus {
        let currentStatus = status()

        guard currentStatus == .notDetermined else {
            return currentStatus
        }

        return await requestAccess()
    }

    func requestAccess() async -> PhotosGalleryAccessStatus {
        await service.requestAuthorization()
    }
}
