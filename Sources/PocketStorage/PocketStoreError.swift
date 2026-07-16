import Foundation

public enum PocketStoreError: Error, LocalizedError {
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
