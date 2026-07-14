import Foundation
import OSLog

private final class UserDefaultsChangeObservation {
    private let notificationCenter: NotificationCenter
    private let notificationToken: NSObjectProtocol

    init(
        notificationCenter: NotificationCenter,
        userDefaults: UserDefaults,
        userDefaultsIdentifier: String,
        continuation: AsyncStream<KeyValueStoreChange>.Continuation
    ) {
        self.notificationCenter = notificationCenter
        self.notificationToken = notificationCenter.addObserver(
            forName: PocketStorageNotification.didChange,
            object: nil,
            queue: nil
        ) { notification in
            guard let notificationUserDefaultsIdentifier = notification.userInfo?[
                PocketStorageNotification.userDefaultsIdentifierUserInfoKey
            ] as? String,
            notificationUserDefaultsIdentifier == userDefaultsIdentifier,
            let keyName = notification.userInfo?[
                PocketStorageNotification.changedKeyUserInfoKey
            ] as? String else {
                return
            }

            continuation.yield(KeyValueStoreChange(keyName: keyName))
        }
    }

    deinit {
        notificationCenter.removeObserver(notificationToken)
    }
}

public actor UserDefaultsStore: KeyValueStore, KeyValueStoreChangeSource {
    public static let standard = UserDefaultsStore()

    private let userDefaults: UserDefaults
    private let userDefaultsIdentifier: String
    private let notificationCenter: NotificationCenter
    private let changeContinuation: AsyncStream<KeyValueStoreChange>.Continuation
    private let changeObservation: UserDefaultsChangeObservation
    private let logger = Logger(subsystem: "PocketStorage", category: "UserDefaultsStore")

    public nonisolated let changes: AsyncStream<KeyValueStoreChange>

    public init(
        suiteName: String? = nil,
        notificationCenter: NotificationCenter = .default
    ) {
        let userDefaults = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
        self.userDefaults = userDefaults
        self.userDefaultsIdentifier = suiteName ?? "standard"
        self.notificationCenter = notificationCenter

        let stream = AsyncStream.makeStream(of: KeyValueStoreChange.self)
        self.changes = stream.stream
        self.changeContinuation = stream.continuation

        let continuation = stream.continuation
        let userDefaultsIdentifier = self.userDefaultsIdentifier
        self.changeObservation = UserDefaultsChangeObservation(
            notificationCenter: notificationCenter,
            userDefaults: userDefaults,
            userDefaultsIdentifier: userDefaultsIdentifier,
            continuation: continuation
        )
    }

    public func value<Value: Codable & Sendable>(for key: StorageKey<Value>) async throws -> Value? {
        if let primitiveType = Value.self as? UserDefaultsValue.Type {
            let primitiveValue = primitiveType.read(from: userDefaults, key: key.name)

            if let primitiveValue,
               let optionalValue = primitiveValue as? PocketStorageOptionalValue,
               optionalValue.isNil {
                return nil
            }

            return primitiveValue as? Value
        }

        guard let data = userDefaults.data(forKey: key.name) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(Value.self, from: data)
        } catch {
            let storageError = PocketStorageError.decodingFailed(
                key: key.name,
                underlying: error
            )
            logger.error("\(storageError.localizedDescription, privacy: .public)")
            throw storageError
        }
    }

    public func set<Value: Codable & Sendable>(
        _ value: Value?,
        for key: StorageKey<Value>
    ) async throws {
        guard let value else {
            await remove(key)
            return
        }

        if let optionalValue = value as? PocketStorageOptionalValue,
           optionalValue.isNil {
            await remove(key)
            return
        }

        if let primitive = value as? UserDefaultsValue {
            primitive.write(to: userDefaults, key: key.name)
            postChange(for: key.name)
        } else {
            do {
                let data = try JSONEncoder().encode(value)
                userDefaults.set(data, forKey: key.name)
                postChange(for: key.name)
            } catch {
                let storageError = PocketStorageError.encodingFailed(
                    key: key.name,
                    underlying: error
                )
                logger.error("\(storageError.localizedDescription, privacy: .public)")
                throw storageError
            }
        }
    }

    public func remove<Value: Codable & Sendable>(_ key: StorageKey<Value>) async {
        userDefaults.removeObject(forKey: key.name)
        postChange(for: key.name)
    }

    private func postChange(for key: String) {
        notificationCenter.post(
            name: PocketStorageNotification.didChange,
            object: nil,
            userInfo: [
                PocketStorageNotification.changedKeyUserInfoKey: key,
                PocketStorageNotification.userDefaultsIdentifierUserInfoKey: userDefaultsIdentifier
            ]
        )
    }
}
