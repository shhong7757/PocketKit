import Foundation

/// Bridges a store's async change stream to a main-actor callback.
public final class KeyValueStoreChangeObserver {
    private var task: Task<Void, Never>?

    public init(
        store: KeyValueStore,
        keyName: String,
        onChange: @escaping @MainActor @Sendable () async -> Void
    ) {
        guard let source = store as? KeyValueStoreChangeSource else { return }

        let changes = source.changes
        self.task = Task { @MainActor in
            for await change in changes where change.keyName == keyName {
                await onChange()
            }
        }
    }

    deinit {
        task?.cancel()
    }
}
