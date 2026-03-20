//
//  RouteMatch.swift
//  Navigator
//
//  Captures extracted values from a matched URL.
//

/// The result of matching a URL against a route pattern.
/// Contains extracted path params, query params, and hash fragment.
public struct RouteMatch {
    /// Path parameters extracted from `:param` segments (e.g. `["id": "123"]`).
    public var params: [String: String]

    /// Query string parameters (e.g. `["q": "swift", "page": "2"]`).
    public var query: [String: String]

    /// Hash fragment, if present (without the `#` prefix).
    public var hash: String?

    public init(
        params: [String: String] = [:],
        query: [String: String] = [:],
        hash: String? = nil
    ) {
        self.params = params
        self.query = query
        self.hash = hash
    }

    /// Subscript for convenient access to path params.
    public subscript(_ key: String) -> String? {
        params[key]
    }

    /// Decode the query dictionary into a `QueryParams` conforming type.
    /// Uses `JSONSerialization` round-trip: dict -> JSON data -> Codable decode.
    /// Falls back to `T()` on any failure.
    public func decodeQuery<T: QueryParams>() -> T {
        guard !query.isEmpty else { return T() }

        // Build a JSON-compatible dictionary, attempting numeric conversion
        var jsonDict: [String: Any] = [:]
        for (key, value) in query {
            if let intVal = Int(value) {
                jsonDict[key] = intVal
            } else if let doubleVal = Double(value) {
                jsonDict[key] = doubleVal
            } else if value == "true" || value == "false" {
                jsonDict[key] = value == "true"
            } else {
                jsonDict[key] = value
            }
        }

        guard let data = try? JSONSerialization.data(withJSONObject: jsonDict),
              let decoded = try? JSONDecoder().decode(T.self, from: data)
        else {
            return T()
        }
        return decoded
    }
}
