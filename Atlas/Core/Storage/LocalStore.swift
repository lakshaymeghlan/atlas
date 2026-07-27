import Foundation

/// Tiny JSON-in-UserDefaults persistence. The prototype's stand-in for Supabase
/// — swap the call sites in the stores when the backend lands.
enum LocalStore {
    enum Key: String {
        case authUser = "atlas.authUser"
        case profile = "atlas.profile"
    }

    private static let defaults = UserDefaults.standard
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func save<T: Encodable>(_ value: T, for key: Key) {
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key.rawValue)
        }
    }

    static func load<T: Decodable>(_ type: T.Type, for key: Key) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    static func remove(_ key: Key) {
        defaults.removeObject(forKey: key.rawValue)
    }
}
