# PocketKit

개인 앱에서 반복해서 사용하는 SwiftUI 컴포넌트와 로컬 저장소를 모아둔 Swift 패키지입니다.

## Modules

- `PocketUI`: SwiftUI 화면 컴포넌트
- `PocketStorage`: 타입 안전한 비동기 key-value 저장소
- `PocketStorageObservation`: `@Observable`과 저장소 연결
- `PocketStorageUI`: SwiftUI 프로퍼티 래퍼

`PocketStorage`는 Swift용 AsyncStorage 스타일의 로컬 저장소입니다. 기본 구현은
`UserDefaultsStore`이며, 값은 `Codable`과 `Sendable`을 만족해야 합니다. 민감한 정보나
대용량 데이터를 저장하는 용도가 아닙니다.

## PocketStorage

```swift
import PocketStorage

struct Profile: Codable, Sendable, Equatable {
    let name: String
}

let store = UserDefaultsStore.standard
let key = StorageKey<Profile>("profile")

try await store.set(Profile(name: "Pocket"), for: key)
let profile = try await store.value(for: key)
await store.remove(key)
```

`UserDefaultsStore`는 actor이므로 저장소 경계를 넘는 작업에는 `await`가 필요합니다.
`StorageKey<Value>`가 키와 값의 타입을 연결하므로 잘못된 타입의 값을 저장하려는 코드를
컴파일 단계에서 막을 수 있습니다.

## Default values

`StoredValueDefinition`은 키와 기본값을 함께 표현합니다.

```swift
let definition = StoredValueDefinition(
    key: StorageKey<Bool>("settings.isEnabled"),
    defaultValue: false
)
```

## Observation

```swift
import PocketStorage
import PocketStorageObservation

@MainActor
let setting = ObservableStoredValue(
    key: StorageKey<Bool>("settings.isEnabled"),
    defaultValue: false
)

setting.value = true
```

저장소에서 읽은 값과 외부 저장소 변경은 observable 값에 반영됩니다. `write`와 `reset`은
비동기 메서드이므로 `await`를 사용합니다.

## SwiftUI

```swift
import PocketStorageUI

struct SettingsView: View {
    @StoredValue(key: "settings.isEnabled", defaultValue: false)
    private var isEnabled: Bool

    var body: some View {
        Toggle("Enabled", isOn: $isEnabled)
    }
}
```

핵심 저장 기능은 `PocketStorage`에만 있으며 Observation과 SwiftUI 연동은 선택적으로
가져올 수 있습니다.
