//
//  RouteQuery.swift
//  Navigator
//
//  Reactive property wrapper that decodes URL query params into a typed QueryParams value.
//  Writing to the wrapped value encodes back to the URL query string.
//

import Sailboat

/// A property wrapper that provides reactive, typed access to URL query parameters.
///
/// Reads the current URL's query string and decodes it into `T` (a `QueryParams` conforming type).
/// Writing encodes `T` back to the URL query string via `Navigator`, which triggers re-renders
/// for any views that depend on `Navigator.url`.
///
/// Usage:
/// ```swift
/// struct SearchPage: Page {
///     @RouteQuery var params: SearchQuery
///
///     var body: some Page {
///         Span("Searching: \(params.q), page \(params.page)")
///     }
/// }
/// ```
@MainActor
@propertyWrapper
public struct RouteQuery<T: QueryParams> {

    public init() {}

    public var wrappedValue: T {
        get {
            // Reading Navigator.url registers a Sailboat signal dependency,
            // so the enclosing Page/Element re-renders when the URL changes.
            let parsed = URLParser.parse(Navigator.url, mode: NavigatorConfig.mode)
            let match = RouteMatch(params: [:], query: parsed.query, hash: parsed.hash)
            return match.decodeQuery()
        }
        nonmutating set {
            // Encode T back to query string and update the URL in-place
            let parsed = URLParser.parse(Navigator.url, mode: NavigatorConfig.mode)
            let pathStr = "/" + parsed.segments.joined(separator: "/")
            let queryStr = URLParser.encodeQuery(newValue)
            var newURL = pathStr
            if !queryStr.isEmpty {
                newURL += "?" + queryStr
            }
            if let h = parsed.hash {
                newURL += "#" + h
            }
            // Use setHash/clearQuery pattern — replaceState so no history entry
            Navigator.replaceURL(newURL)
        }
    }
}
