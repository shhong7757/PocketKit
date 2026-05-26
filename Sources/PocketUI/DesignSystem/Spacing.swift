import CoreGraphics

/// PocketUI에서 반복해서 사용하는 간격 토큰입니다.
///
/// 컴포넌트 기본값과 예제 UI는 이 스케일을 기준으로 간격을 맞춥니다.
/// `space1`은 4pt이며, 이후 숫자는 4pt 단위 배율을 나타냅니다.
public enum PocketUISpacing {
    /// 간격이 필요하지 않은 곳에 사용하는 값입니다.
    public static let space0: CGFloat = 0

    /// 2pt 간격입니다.
    public static let spaceHalf: CGFloat = 2

    /// 4pt 간격입니다.
    public static let space1: CGFloat = 4

    /// 8pt 간격입니다.
    public static let space2: CGFloat = 8

    /// 12pt 간격입니다.
    public static let space3: CGFloat = 12

    /// 16pt 간격입니다.
    public static let space4: CGFloat = 16

    /// 20pt 간격입니다.
    public static let space5: CGFloat = 20

    /// 24pt 간격입니다.
    public static let space6: CGFloat = 24

    /// 32pt 간격입니다.
    public static let space8: CGFloat = 32

    /// 40pt 간격입니다.
    public static let space10: CGFloat = 40
}
