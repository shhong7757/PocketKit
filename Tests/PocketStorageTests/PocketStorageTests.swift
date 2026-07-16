import Foundation
import Testing

@testable import PocketStorage

struct PocketStorageTests {
    private struct CodableFixture: Codable, Equatable, Sendable {
        let name: String
        let count: Int
    }

    private enum Theme: String, Codable, Sendable {
        case light
        case dark
    }

    private enum StoreKeys {
        static let count = PocketStoreKey<Int>("fixture.count")
        static let model = PocketStoreKey<CodableFixture>("fixture.model")
    }

    private enum EncodingFailure: Error {
        case failed
    }

    private struct EncodingFailureFixture: Codable, Sendable {
        init() {}

        init(from decoder: Decoder) throws {
            self.init()
        }

        func encode(to encoder: Encoder) throws {
            throw EncodingFailure.failed
        }
    }

    private struct IsolatedStore {
        let suiteName: String
        let userDefaults: UserDefaults
        let store: PocketStore

        func cleanup() {
            userDefaults.removePersistentDomain(forName: suiteName)
        }
    }

    private func makeIsolatedStore() -> IsolatedStore {
        let suiteName = "PocketStorageTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!

        return IsolatedStore(
            suiteName: suiteName,
            userDefaults: userDefaults,
            store: PocketStore(identifier: suiteName)
        )
    }

    @Test
    func pocketStoreRoundTripsValues() async throws {
        let isolatedStore = makeIsolatedStore()
        defer {
            isolatedStore.cleanup()
        }

        let store = isolatedStore.store

        let primitiveKey = "fixture.count"
        let codableKey = "fixture.model"
        let fixture = CodableFixture(name: "Pocket", count: 3)

        try await store.set(42, forKey: primitiveKey)
        try await store.set(fixture, forKey: codableKey)

        #expect(try await store.value(forKey: primitiveKey, as: Int.self) == 42)
        #expect(try await store.value(forKey: codableKey, as: CodableFixture.self) == fixture)
    }

    @Test
    func typedKeysRoundTripValues() async throws {
        let isolatedStore = makeIsolatedStore()
        defer {
            isolatedStore.cleanup()
        }

        let store = isolatedStore.store
        let fixture = CodableFixture(name: "Pocket", count: 3)

        try await store.set(42, forKey: StoreKeys.count)
        try await store.set(fixture, forKey: StoreKeys.model)

        #expect(try await store.value(forKey: StoreKeys.count) == 42)
        #expect(try await store.value(forKey: StoreKeys.model) == fixture)
    }

    @Test
    func readingValueAsDifferentTypeThrowsDecodingFailed() async throws {
        let isolatedStore = makeIsolatedStore()
        let key = "fixture.isEnabled"

        defer {
            isolatedStore.cleanup()
        }

        let store = isolatedStore.store

        try await store.set(true, forKey: key)

        do {
            _ = try await store.value(forKey: key, as: String.self)
            Issue.record("Expected reading a value as a different type to throw")
        } catch let error as PocketStoreError {
            guard case let .decodingFailed(failedKey, _) = error,
                  failedKey == key else {
                Issue.record("Expected a decodingFailed error for the requested key")
                return
            }
        } catch {
            Issue.record("Expected a PocketStoreError.decodingFailed error")
        }
    }

    @Test
    func readingMissingValueReturnsNil() async throws {
        let isolatedStore = makeIsolatedStore()
        defer {
            isolatedStore.cleanup()
        }

        #expect(try await isolatedStore.store.value(forKey: "fixture.missing", as: Int.self) == nil)
    }

    @Test
    func valueWithDefaultReturnsStoredValueOrDefault() async throws {
        let isolatedStore = makeIsolatedStore()
        defer {
            isolatedStore.cleanup()
        }

        let key = "fixture.isEnabled"
        let store = isolatedStore.store

        #expect(try await store.value(forKey: key, default: false) == false)

        try await store.set(true, forKey: key)

        #expect(try await store.value(forKey: key, default: false) == true)
    }

    @Test
    func encodingFailureThrowsEncodingFailed() async throws {
        let isolatedStore = makeIsolatedStore()
        let key = "fixture.encodingFailure"

        defer {
            isolatedStore.cleanup()
        }

        let store = isolatedStore.store

        do {
            try await store.set(EncodingFailureFixture(), forKey: key)
            Issue.record("Expected encoding to fail")
        } catch let error as PocketStoreError {
            guard case let .encodingFailed(failedKey, _) = error,
                  failedKey == key else {
                Issue.record("Expected an encodingFailed error for the requested key")
                return
            }
        } catch {
            Issue.record("Expected a PocketStoreError.encodingFailed error")
        }
    }

    @Test
    func removeDeletesPersistedValue() async throws {
        let isolatedStore = makeIsolatedStore()
        let key = "fixture.count"

        defer {
            isolatedStore.cleanup()
        }

        let store = isolatedStore.store

        try await store.set(42, forKey: key)
        await store.remove(forKey: key)

        #expect(try await store.value(forKey: key, as: Int.self) == nil)
    }

    @Test
    func malformedCodableDataThrowsDecodingError() async throws {
        let isolatedStore = makeIsolatedStore()
        let key = "fixture.model"

        defer {
            isolatedStore.cleanup()
        }

        isolatedStore.userDefaults.set(Data("not-json".utf8), forKey: key)
        let store = isolatedStore.store

        do {
            _ = try await store.value(forKey: key, as: CodableFixture.self)
            Issue.record("Expected malformed Codable data to throw")
        } catch let error as PocketStoreError {
            guard case .decodingFailed = error else {
                Issue.record("Expected a decodingFailed error")
                return
            }
        } catch {
            Issue.record("Expected a PocketStoreError.decodingFailed error")
        }
    }

    @Test
    func codableEnumRoundTripsAsValue() async throws {
        let isolatedStore = makeIsolatedStore()
        let key = "fixture.theme"

        defer {
            isolatedStore.cleanup()
        }

        let store = isolatedStore.store

        try await store.set(Theme.dark, forKey: key)

        #expect(try await store.value(forKey: key, as: Theme.self) == .dark)
    }

    @Test
    func actorStoreHandlesConcurrentWritesToIndependentKeys() async throws {
        let isolatedStore = makeIsolatedStore()
        defer {
            isolatedStore.cleanup()
        }

        let store = isolatedStore.store

        let keys = (0..<50).map { "fixture.count.\($0)" }

        await withTaskGroup(of: Void.self) { group in
            for (index, key) in keys.enumerated() {
                group.addTask {
                    try? await store.set(index, forKey: key)
                }
            }
        }

        for (index, key) in keys.enumerated() {
            #expect(try await store.value(forKey: key, as: Int.self) == index)
        }
    }

}
