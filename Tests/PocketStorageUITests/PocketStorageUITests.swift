import Foundation
import Testing

@testable import PocketStorage
@testable import PocketStorageUI

@MainActor
struct PocketStorageUITests {
    @Test
    func storedValueProjectedBindingPersistsValue() async throws {
        let suiteName = "PocketStorageUITests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        let store = UserDefaultsStore(suiteName: suiteName)

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        struct Settings {
            @StoredValue(key: "fixture.isEnabled", defaultValue: false)
            var isEnabled: Bool

            init(store: KeyValueStore) {
                _isEnabled = StoredValue(
                    key: "fixture.isEnabled",
                    defaultValue: false,
                    store: store
                )
            }
        }

        let settings = Settings(store: store)
        settings.$isEnabled.wrappedValue = true
        for _ in 0..<10 {
            await Task.yield()
        }

        #expect(try await store.value(for: StorageKey<Bool>("fixture.isEnabled")) == true)
    }

}
