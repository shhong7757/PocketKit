import Foundation

public enum PocketStorageError: Error, LocalizedError {
    case encodingFailed(key: String, underlying: Error)
    case decodingFailed(key: String, underlying: Error)

    public var errorDescription: String? {
        switch self {
        case let .encodingFailed(key, underlying):
            "Failed to encode value for key \(key): \(underlying.localizedDescription)"
        case let .decodingFailed(key, underlying):
            "Failed to decode value for key \(key): \(underlying.localizedDescription)"
        }
    }
}

/// An asynchronous, actor-safe key-value store.
///
/// Individual operations are safe to use from multiple callers, but a sequence
/// of operations such as read-modify-write is not atomic.
public protocol KeyValueStore: Sendable {
    func value<Value: Codable & Sendable>(for key: StorageKey<Value>) async throws -> Value?
    func set<Value: Codable & Sendable>(_ value: Value?, for key: StorageKey<Value>) async throws
    func remove<Value: Codable & Sendable>(_ key: StorageKey<Value>) async
}

public struct KeyValueStoreChange: Sendable {
    public let keyName: String

    public init(keyName: String) {
        self.keyName = keyName
    }
}

/// A key-value store that can asynchronously notify observers when a key changes.
public protocol KeyValueStoreChangeSource: Sendable {
    var changes: AsyncStream<KeyValueStoreChange> { get }
}
