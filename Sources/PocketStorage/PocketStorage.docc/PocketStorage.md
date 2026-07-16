# ``PocketStorage``

Swift에서 `AsyncStorage`처럼 사용할 수 있는 `Codable` 기반 비동기 key-value 저장소입니다.

## 개요

`PocketStorage`는 기본 actor 기반 key-value 저장소 구현을 제공합니다.
값 타입은 `Codable & Sendable`이어야 합니다. 값을 읽을 때 원하는 타입을 함께 전달해
저장된 데이터를 디코딩합니다.

저장된 값과 다른 타입으로 읽으면 ``PocketStoreError/decodingFailed(key:underlying:)``가
발생합니다. 키에 저장된 값이 없으면 오류 대신 `nil`을 반환합니다.

```swift
import PocketStorage

struct Profile: Codable, Sendable {
    let name: String
}

let store = PocketStore.shared
try await store.set(Profile(name: "Pocket"), forKey: "profile")
let profile = try await store.value(forKey: "profile", as: Profile.self)
let nickname = try await store.value(forKey: "nickname", default: "Pocket")

let enabledKey = PocketStoreKey<Bool>("settings.isEnabled")
try await store.set(true, forKey: enabledKey)
let enabled = try await store.value(forKey: enabledKey, default: false)
```

저장과 삭제는 별도의 작업입니다. `set`은 값을 저장하고, 저장된 값을 없애려면
`remove(forKey:)`를 호출합니다.

`PocketStore`는 actor이므로 저장소 작업에는 `await`가 필요합니다. 앱 설정,
작은 사용자 환경설정, 마지막으로 선택한 화면처럼 용량이 작고 민감하지 않은 값을
저장하는 데 적합합니다. 비밀번호, 토큰, 대용량 파일 저장소로 사용하지 마세요.

## 값의 저장 방식

모든 값은 JSON 데이터로 인코딩해 저장합니다. 따라서 문자열, 숫자, `Date`, `Data`,
`URL`, 문자열 배열과 사용자 정의 `Codable` 타입이 같은 방식으로 처리됩니다.
호출자는 구체적인 저장 방식보다 자신의 모델 타입에 집중할 수 있습니다.

키와 값의 타입을 함께 관리하고 싶다면 ``PocketStoreKey``를 사용할 수 있습니다.
문자열 기반 API도 그대로 사용할 수 있습니다.

## Topics

### 저장소 핵심

- ``PocketStore``

### 오류

- ``PocketStoreError``
