import SwiftUI

/// 갤러리의 선택 상태 바인딩입니다.
public enum GallerySelection<ID: Hashable> {
    /// 선택 상태를 관리하지 않습니다.
    case none

    /// 선택된 항목 ID 집합을 관리합니다.
    case multiple(Binding<Set<ID>>)

    func contains(_ id: ID) -> Bool {
        switch self {
        case .none:
            return false
        case .multiple(let selectedIDs):
            return selectedIDs.wrappedValue.contains(id)
        }
    }

    /// 전달한 ID의 선택 상태를 토글합니다.
    ///
    /// 선택 모드가 활성화되어 탭을 소비했으면 `true`를 반환합니다.
    @discardableResult
    func toggleSelection(for id: ID) -> Bool {
        switch self {
        case .none:
            return false
        case .multiple(let selectedIDs):
            if selectedIDs.wrappedValue.contains(id) {
                selectedIDs.wrappedValue.remove(id)
            } else {
                selectedIDs.wrappedValue.insert(id)
            }
            return true
        }
    }
}
