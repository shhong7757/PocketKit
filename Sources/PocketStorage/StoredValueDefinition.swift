import Foundation

public struct StoredValueDefinition<Value: Codable & Sendable>: Sendable {
    public let key: StorageKey<Value>
    public let defaultValue: Value

    public init(key: StorageKey<Value>, defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
    }
}
