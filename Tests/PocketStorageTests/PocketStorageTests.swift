import Foundation
import Testing

@testable import PocketStorage
@testable import PocketStorageObservation

private actor DelayedKeyValueStore: KeyValueStore {
    private var values: [String: Data] = [:]

    func value<Value: Codable & Sendable>(for key: StorageKey<Value>) async throws -> Value? {
        guard let data = values[key.name] else { return nil }
        return try JSONDecoder().decode(Value.self, from: data)
    }

    func set<Value: Codable & Sendable>(
        _ value: Value?,
        for key: StorageKey<Value>
    ) async throws {
        guard let value else {
            values.removeValue(forKey: key.name)
            return
        }

        if (value as? Bool) == true {
            do {
                try await Task.sleep(nanoseconds: 50_000_000)
            } catch {
                // The store deliberately completes a cancelled write so the
                // observable must wait for the underlying operation to finish.
            }
        }

        values[key.name] = try JSONEncoder().encode(value)
    }

    func remove<Value: Codable & Sendable>(_ key: StorageKey<Value>) async {
        values.removeValue(forKey: key.name)
    }
}

@MainActor
struct PocketStorageTests {
    private struct CodableFixture: Codable, Equatable, Sendable {
        let name: String
        let count: Int
    }

    private enum Theme: String, Codable, Sendable {
        case light
        case dark
    }

    @MainActor
    private final class EventBox {
        var count = 0
    }

    @Test
    func changeObserverReceivesChangesForSameBackingUserDefaults() async throws {
        let suiteName = "PocketStorageTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        let notificationCenter = NotificationCenter()
        let observedStore = UserDefaultsStore(
            suiteName: suiteName,
            notificationCenter: notificationCenter
        )
        let writingStore = UserDefaultsStore(
            suiteName: suiteName,
            notificationCenter: notificationCenter
        )
        let key = StorageKey<Bool>("fixture.isEnabled")
        let events = EventBox()
        let observer = KeyValueStoreChangeObserver(store: observedStore, keyName: key.name) {
            events.count += 1
        }

        defer {
            _ = observer
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        try await writingStore.set(true, for: key)
        for _ in 0..<10 {
            await Task.yield()
        }

        #expect(events.count == 1)
    }

    @Test
    func userDefaultsStoreRoundTripsPrimitiveAndCodableValues() async throws {
        let suiteName = "PocketStorageTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        let store = UserDefaultsStore(suiteName: suiteName)

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let primitiveKey = StorageKey<Int>("fixture.count")
        let codableKey = StorageKey<CodableFixture>("fixture.model")
        let fixture = CodableFixture(name: "Pocket", count: 3)

        try await store.set(42, for: primitiveKey)
        try await store.set(fixture, for: codableKey)

        #expect(try await store.value(for: primitiveKey) == 42)
        #expect(try await store.value(for: codableKey) == fixture)
    }

    @Test
    func removeDeletesPersistedValue() async throws {
        let suiteName = "PocketStorageTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        let store = UserDefaultsStore(suiteName: suiteName)
        let key = StorageKey<Int>("fixture.count")

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        try await store.set(42, for: key)
        await store.remove(key)

        #expect(try await store.value(for: key) == nil)
    }

    @Test
    func malformedCodableDataThrowsDecodingError() async throws {
        let suiteName = "PocketStorageTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        let key = StorageKey<CodableFixture>("fixture.model")

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        userDefaults.set(Data("not-json".utf8), forKey: key.name)
        let store = UserDefaultsStore(suiteName: suiteName)

        do {
            _ = try await store.value(for: key)
            Issue.record("Expected malformed Codable data to throw")
        } catch let error as PocketStorageError {
            guard case .decodingFailed = error else {
                Issue.record("Expected a decodingFailed error")
                return
            }
        }
    }

    @Test
    func codableEnumRoundTripsAsValue() async throws {
        let suiteName = "PocketStorageTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        let store = UserDefaultsStore(suiteName: suiteName)
        let key = StorageKey<Theme>("fixture.theme")

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        try await store.set(.dark, for: key)

        #expect(try await store.value(for: key) == .dark)
    }

    @Test
    func actorStoreHandlesConcurrentWritesToIndependentKeys() async throws {
        let suiteName = "PocketStorageTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        let store = UserDefaultsStore(suiteName: suiteName)

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let keys = (0..<50).map { StorageKey<Int>("fixture.count.\($0)") }

        await withTaskGroup(of: Void.self) { group in
            for (index, key) in keys.enumerated() {
                group.addTask {
                    try? await store.set(index, for: key)
                }
            }
        }

        for (index, key) in keys.enumerated() {
            #expect(try await store.value(for: key) == index)
        }
    }

    @Test
    func notificationsDoNotCrossDifferentUserDefaultsStores() async throws {
        let firstSuiteName = "PocketStorageTests.\(UUID().uuidString)"
        let secondSuiteName = "PocketStorageTests.\(UUID().uuidString)"
        let firstDefaults = UserDefaults(suiteName: firstSuiteName)!
        let secondDefaults = UserDefaults(suiteName: secondSuiteName)!
        let notificationCenter = NotificationCenter()

        defer {
            firstDefaults.removePersistentDomain(forName: firstSuiteName)
            secondDefaults.removePersistentDomain(forName: secondSuiteName)
        }

        let observedStore = UserDefaultsStore(
            suiteName: firstSuiteName,
            notificationCenter: notificationCenter
        )
        let writingStore = UserDefaultsStore(
            suiteName: secondSuiteName,
            notificationCenter: notificationCenter
        )
        let key = StorageKey<Bool>("fixture.isEnabled")
        let value = ObservableStoredValue(
            key: key,
            defaultValue: false,
            store: observedStore
        )

        try await writingStore.set(true, for: key)
        for _ in 0..<10 {
            await Task.yield()
        }

        #expect(value.value == false)
    }

    @Test
    func observableValueReflectsWritesFromAnotherStore() async throws {
        let suiteName = "PocketStorageTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        let notificationCenter = NotificationCenter()

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let observedStore = UserDefaultsStore(
            suiteName: suiteName,
            notificationCenter: notificationCenter
        )
        let writingStore = UserDefaultsStore(
            suiteName: suiteName,
            notificationCenter: notificationCenter
        )
        let key = StorageKey<Bool>("fixture.isEnabled")
        let value = ObservableStoredValue(
            key: key,
            defaultValue: false,
            store: observedStore
        )

        #expect(value.value == false)

        try await writingStore.set(true, for: key)
        for _ in 0..<10 {
            await Task.yield()
        }

        #expect(value.value == true)
    }

    @Test
    func observableValueAssignmentPersistsValue() async throws {
        let suiteName = "PocketStorageTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let store = UserDefaultsStore(suiteName: suiteName)
        let key = StorageKey<Bool>("fixture.isEnabled")
        let value = ObservableStoredValue(key: key, defaultValue: false, store: store)

        value.value = true
        for _ in 0..<10 {
            await Task.yield()
        }

        #expect(try await store.value(for: key) == true)
    }

    @Test
    func observableValuePersistsLatestRapidAssignment() async throws {
        let store = DelayedKeyValueStore()
        let key = StorageKey<Bool>("fixture.isEnabled")
        let value = ObservableStoredValue(
            key: key,
            defaultValue: false,
            store: store
        )

        value.value = true
        await Task.yield()
        value.value = false

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(try await store.value(for: key) == false)
        #expect(value.value == false)
    }

}
