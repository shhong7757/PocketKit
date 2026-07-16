import Foundation
import OSLog

public actor PocketStore {
    public static let shared = PocketStore()

    private let userDefaults: UserDefaults
    private let logger = Logger(subsystem: "PocketStorage", category: "PocketStore")

    public init(identifier: String? = nil) {
        if let identifier {
            guard let userDefaults = UserDefaults(suiteName: identifier) else {
                preconditionFailure("Invalid UserDefaults suite identifier: \(identifier)")
            }

            self.userDefaults = userDefaults
        } else {
            self.userDefaults = .standard
        }
    }

    public func value<Value: Codable & Sendable>(
        forKey key: String,
        as type: Value.Type
    ) async throws -> Value? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            let storageError = PocketStoreError.decodingFailed(
                key: key,
                underlying: error
            )
            logger.error("\(storageError.localizedDescription, privacy: .public)")
            throw storageError
        }
    }

    public func value<Value: Codable & Sendable>(
        forKey key: String,
        default defaultValue: Value
    ) async throws -> Value {
        try await value(forKey: key, as: Value.self) ?? defaultValue
    }

    public func value<Value: Codable & Sendable>(
        forKey key: PocketStoreKey<Value>
    ) async throws -> Value? {
        try await value(forKey: key.name, as: Value.self)
    }

    public func value<Value: Codable & Sendable>(
        forKey key: PocketStoreKey<Value>,
        default defaultValue: Value
    ) async throws -> Value {
        try await value(forKey: key.name, default: defaultValue)
    }

    public func set<Value: Codable & Sendable>(
        _ value: Value,
        forKey key: String
    ) async throws {
        do {
            let data = try JSONEncoder().encode(value)
            userDefaults.set(data, forKey: key)
        } catch {
            let storageError = PocketStoreError.encodingFailed(
                key: key,
                underlying: error
            )
            logger.error("\(storageError.localizedDescription, privacy: .public)")
            throw storageError
        }
    }

    public func set<Value: Codable & Sendable>(
        _ value: Value,
        forKey key: PocketStoreKey<Value>
    ) async throws {
        try await set(value, forKey: key.name)
    }

    public func remove(forKey key: String) async {
        userDefaults.removeObject(forKey: key)
    }

    public func remove<Value: Codable & Sendable>(forKey key: PocketStoreKey<Value>) async {
        await remove(forKey: key.name)
    }

}
