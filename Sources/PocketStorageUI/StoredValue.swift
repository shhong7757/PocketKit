import Foundation
import OSLog
import PocketStorage
import SwiftUI

private enum StoredValueLogging {
    static let logger = Logger(subsystem: "PocketStorage", category: "StoredValue")
}

/// A SwiftUI property wrapper for a value backed by an asynchronous `KeyValueStore`.
///
/// The wrapper keeps an in-view value in SwiftUI state and persists assignments
/// asynchronously. Use `write(_:)` when the write error must be handled.
@propertyWrapper
public struct StoredValue<Value: Codable & Sendable>: DynamicProperty {
    @State private var value: Value
    @State private var hasLoaded = false
    @State private var changeObserver: KeyValueStoreChangeObserver?
    @State private var pendingWriteTask: Task<Void, Never>?

    private let key: StorageKey<Value>
    private let store: KeyValueStore
    private let defaultValue: Value

    public var wrappedValue: Value {
        get { value }
        nonmutating set {
            let previousValue = value
            let stateBinding = $value
            let pendingTaskBinding = $pendingWriteTask
            let store = store
            let key = key

            stateBinding.wrappedValue = newValue
            pendingTaskBinding.wrappedValue?.cancel()
            let previousTask = pendingTaskBinding.wrappedValue
            let task = Task { @MainActor in
                _ = await previousTask?.value
                guard !Task.isCancelled else { return }

                do {
                    try await store.set(newValue, for: key)
                    guard !Task.isCancelled else { return }
                } catch {
                    guard !Task.isCancelled else { return }
                    stateBinding.wrappedValue = previousValue
                    Self.log(error, operation: "write", key: key)
                }
            }
            pendingTaskBinding.wrappedValue = task
        }
    }

    public var projectedValue: Binding<Value> {
        let stateBinding = $value
        let pendingTaskBinding = $pendingWriteTask
        let key = key
        let store = store

        return Binding(
            get: { stateBinding.wrappedValue },
            set: { newValue in
                let previousValue = stateBinding.wrappedValue
                stateBinding.wrappedValue = newValue

                pendingTaskBinding.wrappedValue?.cancel()
                let previousTask = pendingTaskBinding.wrappedValue
                let task = Task { @MainActor in
                    _ = await previousTask?.value
                    guard !Task.isCancelled else { return }

                    do {
                        try await store.set(newValue, for: key)
                        guard !Task.isCancelled else { return }
                    } catch {
                        guard !Task.isCancelled else { return }
                        stateBinding.wrappedValue = previousValue
                        Self.log(error, operation: "write", key: key)
                    }
                }
                pendingTaskBinding.wrappedValue = task
            }
        )
    }

    public init(
        _ definition: StoredValueDefinition<Value>,
        store: KeyValueStore = UserDefaultsStore.standard
    ) {
        self.init(wrappedValue: definition.defaultValue, key: definition.key, store: store)
    }

    public init(
        wrappedValue defaultValue: Value,
        key: StorageKey<Value>,
        store: KeyValueStore = UserDefaultsStore.standard
    ) {
        self.key = key
        self.store = store
        self.defaultValue = defaultValue
        self._value = State(initialValue: defaultValue)
        self._changeObserver = State(initialValue: nil)
        self._pendingWriteTask = State(initialValue: nil)
    }

    public init(
        wrappedValue defaultValue: Value,
        key: String,
        store: KeyValueStore = UserDefaultsStore.standard
    ) {
        self.init(wrappedValue: defaultValue, key: StorageKey<Value>(key), store: store)
    }

    public init(
        key: StorageKey<Value>,
        defaultValue: Value,
        store: KeyValueStore = UserDefaultsStore.standard
    ) {
        self.init(wrappedValue: defaultValue, key: key, store: store)
    }

    public init(
        key: String,
        defaultValue: Value,
        store: KeyValueStore = UserDefaultsStore.standard
    ) {
        self.init(wrappedValue: defaultValue, key: StorageKey<Value>(key), store: store)
    }

    public mutating func update() {
        _value.update()
        _hasLoaded.update()
        _changeObserver.update()

        if !hasLoaded {
            hasLoaded = true
            refreshFromStore()
        }

        guard changeObserver == nil else { return }

        let stateBinding = $value
        let store = store
        let key = key
        let defaultValue = defaultValue

        changeObserver = KeyValueStoreChangeObserver(store: store, keyName: key.name) {
            do {
                stateBinding.wrappedValue = try await store.value(for: key) ?? defaultValue
            } catch {
                stateBinding.wrappedValue = defaultValue
                Self.log(error, operation: "read", key: key)
            }
        }
    }

    public func read() async throws -> Value {
        try await store.value(for: key) ?? defaultValue
    }

    public func write(_ value: Value) async throws {
        let pendingTask = pendingWriteTask
        pendingTask?.cancel()
        _ = await pendingTask?.value
        try await store.set(value, for: key)
        self.value = value
    }

    public func reset() async {
        let pendingTask = pendingWriteTask
        pendingTask?.cancel()
        _ = await pendingTask?.value
        await store.remove(key)
        value = defaultValue
    }

    private func refreshFromStore() {
        let stateBinding = $value
        let store = store
        let key = key
        let defaultValue = defaultValue

        Task { @MainActor in
            do {
                stateBinding.wrappedValue = try await store.value(for: key) ?? defaultValue
            } catch {
                stateBinding.wrappedValue = defaultValue
                Self.log(error, operation: "read", key: key)
            }
        }
    }

    private static func log(
        _ error: Error,
        operation: String,
        key: StorageKey<Value>
    ) {
        StoredValueLogging.logger.error(
            "Failed to \(operation) value for key \(key.name, privacy: .public): \(String(describing: error), privacy: .public)"
        )
    }
}
