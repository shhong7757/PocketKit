import Foundation

internal protocol UserDefaultsValue: Codable & Sendable {
    static func read(from defaults: UserDefaults, key: String) -> Self?
    func write(to defaults: UserDefaults, key: String)
}

internal protocol PocketStorageOptionalValue {
    var isNil: Bool { get }
}

extension Optional: PocketStorageOptionalValue {
    var isNil: Bool {
        switch self {
        case .none:
            true
        case .some:
            false
        }
    }
}

extension String: UserDefaultsValue {
    static func read(from defaults: UserDefaults, key: String) -> String? {
        defaults.string(forKey: key)
    }

    func write(to defaults: UserDefaults, key: String) {
        defaults.set(self, forKey: key)
    }
}

extension [String]: UserDefaultsValue {
    static func read(from defaults: UserDefaults, key: String) -> [String]? {
        defaults.stringArray(forKey: key)
    }

    func write(to defaults: UserDefaults, key: String) {
        defaults.set(self, forKey: key)
    }
}

extension Bool: UserDefaultsValue {
    static func read(from defaults: UserDefaults, key: String) -> Bool? {
        guard defaults.object(forKey: key) != nil else { return nil }
        return defaults.bool(forKey: key)
    }

    func write(to defaults: UserDefaults, key: String) {
        defaults.set(self, forKey: key)
    }
}

extension Int: UserDefaultsValue {
    static func read(from defaults: UserDefaults, key: String) -> Int? {
        guard defaults.object(forKey: key) != nil else { return nil }
        return defaults.integer(forKey: key)
    }

    func write(to defaults: UserDefaults, key: String) {
        defaults.set(self, forKey: key)
    }
}

extension Double: UserDefaultsValue {
    static func read(from defaults: UserDefaults, key: String) -> Double? {
        guard defaults.object(forKey: key) != nil else { return nil }
        return defaults.double(forKey: key)
    }

    func write(to defaults: UserDefaults, key: String) {
        defaults.set(self, forKey: key)
    }
}

extension Float: UserDefaultsValue {
    static func read(from defaults: UserDefaults, key: String) -> Float? {
        guard defaults.object(forKey: key) != nil else { return nil }
        return defaults.float(forKey: key)
    }

    func write(to defaults: UserDefaults, key: String) {
        defaults.set(self, forKey: key)
    }
}

extension Date: UserDefaultsValue {
    static func read(from defaults: UserDefaults, key: String) -> Date? {
        defaults.object(forKey: key) as? Date
    }

    func write(to defaults: UserDefaults, key: String) {
        defaults.set(self, forKey: key)
    }
}

extension Data: UserDefaultsValue {
    static func read(from defaults: UserDefaults, key: String) -> Data? {
        defaults.data(forKey: key)
    }

    func write(to defaults: UserDefaults, key: String) {
        defaults.set(self, forKey: key)
    }
}

extension URL: UserDefaultsValue {
    static func read(from defaults: UserDefaults, key: String) -> URL? {
        defaults.url(forKey: key)
    }

    func write(to defaults: UserDefaults, key: String) {
        defaults.set(self, forKey: key)
    }
}

extension Optional: UserDefaultsValue where Wrapped: UserDefaultsValue {
    static func read(from defaults: UserDefaults, key: String) -> Self? {
        Wrapped.read(from: defaults, key: key)
    }

    func write(to defaults: UserDefaults, key: String) {
        if let wrappedValue = self {
            wrappedValue.write(to: defaults, key: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
