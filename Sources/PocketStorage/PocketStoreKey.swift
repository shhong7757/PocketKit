public struct PocketStoreKey<Value: Codable & Sendable>: Sendable {
    public let name: String

    public init(_ name: String) {
        self.name = name
    }
}
