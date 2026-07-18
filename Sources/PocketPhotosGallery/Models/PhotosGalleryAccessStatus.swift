public enum PhotosGalleryAccessStatus: Equatable, Sendable {
    case notDetermined
    case authorized
    case limited
    case denied
    case restricted

    public var isAccessible: Bool {
        self == .authorized || self == .limited
    }
}
