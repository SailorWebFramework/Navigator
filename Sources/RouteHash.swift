//
//  RouteHash.swift
//  Navigator
//
//  Reactive property wrapper for typed and untyped hash fragment access.
//

import Sailboat

/// A property wrapper that provides reactive, typed access to the URL hash fragment.
///
/// **Typed usage** (enum-based hash navigation):
/// ```swift
/// @RouteHash var section: DocsSection?
/// ```
/// Decodes the hash fragment into a `HashRoute` enum case. Returns `nil` if the hash
/// doesn't match any case.
///
/// **Untyped usage** (raw string hash):
/// ```swift
/// @RouteHash var anchor: String?
/// ```
/// Reads and writes the raw hash fragment string directly.
///
/// Reading registers a Sailboat signal dependency on `Navigator.url`, so the enclosing
/// Page re-renders when the URL hash changes. Writing updates the URL via `Navigator`.
@MainActor
@propertyWrapper
public struct RouteHash<H: Equatable> {

    public init() {}

    public var wrappedValue: H? {
        get {
            // Reading Navigator.url registers the Sailboat signal dependency.
            let parsed = URLParser.parse(Navigator.url, mode: NavigatorConfig.mode)
            guard let hashValue = parsed.hash, !hashValue.isEmpty else {
                return nil
            }
            return Self.decode(hashValue)
        }
        nonmutating set {
            let encoded = Self.encode(newValue)
            Navigator.setHash(encoded)
        }
    }

    // MARK: - Type-specific decode/encode

    /// Decode a hash string into the wrapped type.
    private static func decode(_ hashValue: String) -> H? {
        // Typed HashRoute enum
        if let hashRouteType = H.self as? any HashRoute.Type {
            return _decodeHashRoute(hashRouteType, from: hashValue) as? H
        }
        // Raw String
        if H.self == String.self {
            return hashValue as? H
        }
        return nil
    }

    /// Encode the wrapped value back to a hash string.
    private static func encode(_ value: H?) -> String? {
        guard let value = value else { return nil }
        // Typed HashRoute enum
        if let hashRoute = value as? any HashRoute {
            return hashRoute.rawValue
        }
        // Raw String
        if let str = value as? String {
            return str
        }
        return nil
    }
}

/// Helper to open the existential and call `init(rawValue:)`.
private func _decodeHashRoute<R: HashRoute>(_ type: R.Type, from rawValue: String) -> R? {
    R(rawValue: rawValue)
}
