import Foundation

internal enum PocketStorageNotification {
    static let didChange = Notification.Name("PocketStorage.didChange")
    static let changedKeyUserInfoKey = "PocketStorage.changedKey"
    static let userDefaultsIdentifierUserInfoKey = "PocketStorage.userDefaultsIdentifier"
}
