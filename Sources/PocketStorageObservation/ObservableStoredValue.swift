import Foundation
import Observation
import OSLog
import PocketStorage

/// An observable, bindable value backed by an asynchronous `KeyValueStore`.
@MainActor
@Observable
public final class ObservableStoredValue<Value: Codable & Sendable> {
    public var value: Value {
        didSet {
            guard !isUpdatingFromStore else { return }

            let newValue = value
            let previousValue = oldValue
            pendingWriteTask?.cancel()
            let previousTask = pendingWriteTask
            pendingWriteTask = Task { @MainActor [weak self] in
                _ = await previousTask?.value
                guard !Task.isCancelled else { return }
                guard let self else { return }

                do {
                    try await store.set(newValue, for: key)
                    guard !Task.isCancelled else { return }
                } catch {
                    guard !Task.isCancelled else { return }
                    isUpdatingFromStore = true
                    value = previousValue
                    isUpdatingFromStore = false
                    log(error, operation: "write")
                }
            }
        }
    }

    @ObservationIgnored
    private let key: StorageKey<Value>

    @ObservationIgnored
    private let defaultValue: Value

    @ObservationIgnored
    private let store: KeyValueStore

    @ObservationIgnored
    private var isUpdatingFromStore = false

    @ObservationIgnored
    private var didReceiveStoreChange = false

    @ObservationIgnored
    private var pendingWriteTask: Task<Void, Never>?

    @ObservationIgnored
    private var changeObserver: KeyValueStoreChangeObserver?

    @ObservationIgnored
    private let logger = Logger(subsystem: "PocketStorage", category: "ObservableStoredValue")

    public init(
        _ definition: StoredValueDefinition<Value>,
        store: KeyValueStore = UserDefaultsStore.standard
    ) {
        self.key = definition.key
        self.defaultValue = definition.defaultValue
        self.store = store
        self.pendingWriteTask = nil
        self.isUpdatingFromStore = true
        self.value = definition.defaultValue
        self.isUpdatingFromStore = false
        observeStoreChanges()

        Task { @MainActor [weak self] in
            await self?.refreshInitially()
        }
    }

    public convenience init(
        key: StorageKey<Value>,
        defaultValue: Value,
        store: KeyValueStore = UserDefaultsStore.standard
    ) {
        self.init(
            StoredValueDefinition(key: key, defaultValue: defaultValue),
            store: store
        )
    }

    public convenience init(
        key: String,
        defaultValue: Value,
        store: KeyValueStore = UserDefaultsStore.standard
    ) {
        self.init(
            key: StorageKey<Value>(key),
            defaultValue: defaultValue,
            store: store
        )
    }

    /// Refreshes the value from the store and falls back to the default on read failure.
    public func refresh() async {
        do {
            setValueFromStore(try await readValueFromStore())
        } catch {
            log(error, operation: "read")
            setValueFromStore(defaultValue)
        }
    }

    /// Persists a value and throws when the store cannot encode it.
    public func write(_ value: Value) async throws {
        let pendingTask = pendingWriteTask
        pendingTask?.cancel()
        _ = await pendingTask?.value
        try await store.set(value, for: key)
        setValueFromStore(value)
    }

    /// Removes the persisted value so the observable value becomes its default.
    public func reset() async {
        let pendingTask = pendingWriteTask
        pendingTask?.cancel()
        _ = await pendingTask?.value
        await store.remove(key)
        setValueFromStore(defaultValue)
    }

    private func readValueFromStore() async throws -> Value {
        try await store.value(for: key) ?? defaultValue
    }

    private func observeStoreChanges() {
        changeObserver = KeyValueStoreChangeObserver(
            store: store,
            keyName: key.name
        ) { [weak self] in
            self?.didReceiveStoreChange = true
            await self?.refresh()
        }
    }

    private func refreshInitially() async {
        do {
            let value = try await readValueFromStore()
            guard !didReceiveStoreChange else { return }
            setValueFromStore(value)
        } catch {
            guard !didReceiveStoreChange else { return }
            log(error, operation: "read")
            setValueFromStore(defaultValue)
        }
    }

    private func setValueFromStore(_ value: Value) {
        isUpdatingFromStore = true
        self.value = value
        isUpdatingFromStore = false
    }

    private func log(_ error: Error, operation: String) {
        logger.error(
            "Failed to \(operation) value for key \(self.key.name, privacy: .public): \(String(describing: error), privacy: .public)"
        )
    }
}
