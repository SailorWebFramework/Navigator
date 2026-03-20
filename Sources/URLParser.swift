//
//  URLParser.swift
//  Navigator
//
//  Parses URLs into path segments, query params, and hash fragments.
//

import Foundation

/// Represents the routing mode: path-based or hash-based URLs.
public enum NavigatorMode: Sendable {
    /// Path mode: `/users/123` — requires server-side SPA fallback.
    case path

    /// Hash mode: `/#/users/123` — works with any static file server.
    case hash
}

/// Parsed components of a URL.
public struct ParsedURL {
    /// Path segments (e.g. `["users", "123"]`). Root `/` yields `[]`.
    public var segments: [String]

    /// Query string key-value pairs.
    public var query: [String: String]

    /// Hash fragment without the `#` prefix, or `nil`.
    public var hash: String?

    public init(segments: [String] = [], query: [String: String] = [:], hash: String? = nil) {
        self.segments = segments
        self.query = query
        self.hash = hash
    }
}

/// URL parsing utilities for Navigator.
public enum URLParser {

    /// Parse a full URL string into its components, respecting the given routing mode.
    public static func parse(_ url: String, mode: NavigatorMode = .path) -> ParsedURL {
        switch mode {
        case .path:
            return parsePath(url)
        case .hash:
            return parseHash(url)
        }
    }

    /// Split a path string into non-empty segments.
    /// `"/"` -> `[]`, `"/users/123"` -> `["users", "123"]`
    public static func pathSegments(from path: String) -> [String] {
        // Strip query and hash before splitting
        let clean = path.components(separatedBy: "?").first ?? path
        let clean2 = clean.components(separatedBy: "#").first ?? clean
        return clean2.split(separator: "/").map(String.init)
    }

    /// Parse query string (everything after `?` and before `#`) into a dictionary.
    public static func parseQueryString(_ queryString: String) -> [String: String] {
        guard !queryString.isEmpty else { return [:] }
        var result: [String: String] = [:]
        let pairs = queryString.split(separator: "&")
        for pair in pairs {
            let parts = pair.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0]).removingPercentEncoding ?? String(parts[0])
                let value = String(parts[1]).removingPercentEncoding ?? String(parts[1])
                result[key] = value
            } else if parts.count == 1 {
                let key = String(parts[0]).removingPercentEncoding ?? String(parts[0])
                result[key] = ""
            }
        }
        return result
    }

    /// Encode a dictionary into a query string (without leading `?`).
    public static func encodeQueryString(_ params: [String: String]) -> String {
        guard !params.isEmpty else { return "" }
        return params.sorted(by: { $0.key < $1.key })
            .map { key, value in
                let k = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let v = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(k)=\(v)"
            }
            .joined(separator: "&")
    }

    /// Encode a `QueryParams` value into a query string.
    public static func encodeQuery<T: QueryParams>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return "" }

        var params: [String: String] = [:]
        for (key, val) in dict {
            params[key] = "\(val)"
        }
        return encodeQueryString(params)
    }

    // MARK: - Private

    /// Parse a path-mode URL.
    private static func parsePath(_ url: String) -> ParsedURL {
        // Strip scheme + host: "https://example.com/path" -> "/path..."
        var working = url
        if let range = working.range(of: "://") {
            let afterScheme = working[range.upperBound...]
            if let slashIndex = afterScheme.firstIndex(of: "/") {
                working = String(afterScheme[slashIndex...])
            } else {
                working = "/"
            }
        }

        // Extract hash
        var hash: String? = nil
        if let hashIndex = working.firstIndex(of: "#") {
            let hashValue = String(working[working.index(after: hashIndex)...])
            hash = hashValue.isEmpty ? nil : hashValue
            working = String(working[..<hashIndex])
        }

        // Extract query
        var query: [String: String] = [:]
        if let qIndex = working.firstIndex(of: "?") {
            let queryString = String(working[working.index(after: qIndex)...])
            query = parseQueryString(queryString)
            working = String(working[..<qIndex])
        }

        let segments = pathSegments(from: working)
        return ParsedURL(segments: segments, query: query, hash: hash)
    }

    /// Parse a hash-mode URL: `https://example.com/#/users/123?q=x`
    private static func parseHash(_ url: String) -> ParsedURL {
        // Find the `#` — everything after it is the "virtual" path
        guard let hashIndex = url.firstIndex(of: "#") else {
            // No hash means root
            return ParsedURL()
        }

        let afterHash = String(url[url.index(after: hashIndex)...])

        // Now parse afterHash as if it were a path URL
        var working = afterHash

        // Extract real hash (second #, if any — unlikely but handle)
        var hash: String? = nil

        // Extract query from the virtual path
        var query: [String: String] = [:]
        if let qIndex = working.firstIndex(of: "?") {
            let queryString = String(working[working.index(after: qIndex)...])
            query = parseQueryString(queryString)
            working = String(working[..<qIndex])
        }

        let segments = pathSegments(from: working)
        return ParsedURL(segments: segments, query: query, hash: hash)
    }
}
