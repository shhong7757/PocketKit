import Foundation

public struct StorageKey<Value: Codable & Sendable>: Hashable, Sendable {
    public let name: String

    public init(_ name: String) {
        self.name = name
    }
}
