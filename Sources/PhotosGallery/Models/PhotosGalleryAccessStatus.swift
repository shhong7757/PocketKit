/// 사진 보관함 접근 권한 상태입니다.
public enum PhotosGalleryAccessStatus: Equatable, Sendable {
    /// 아직 사용자에게 권한을 요청하지 않았습니다.
    case notDetermined

    /// 사진 보관함 전체 접근이 허용되었습니다.
    case authorized

    /// 사진 보관함의 일부 항목에 대한 접근이 허용되었습니다.
    case limited

    /// 사용자가 사진 보관함 접근을 거부했습니다.
    case denied

    /// 시스템 정책으로 사진 보관함 접근이 제한되었습니다.
    case restricted

    /// 갤러리가 사진 보관함의 항목을 읽을 수 있는지 여부입니다.
    public var isAccessible: Bool {
        self == .authorized || self == .limited
    }
}
