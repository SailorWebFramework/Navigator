//
//  RoutePattern.swift
//  Navigator
//
//  Defines route pattern types and the URL matching engine.
//

import Foundation

/// A pattern that describes how a URL maps to a route value.
public enum RoutePattern<R: Routable>: @unchecked Sendable {
    /// Exact static path match (e.g. `/` or `/about`).
    case exact(String, R)

    /// Parameterized path match (e.g. `/users/:id`).
    /// The closure receives a `RouteMatch` with extracted param values.
    case param(String, @Sendable (RouteMatch) -> R?)

    /// Path match with query string decoding (e.g. `/search`).
    /// The closure receives a `RouteMatch` for query decoding.
    case query(String, @Sendable (RouteMatch) -> R)

    /// Nested route delegation (e.g. `/admin/*`).
    /// Strips the prefix and delegates to a child `Routable` type.
    case nested(String, any Routable.Type, @Sendable (any Routable) -> R)
}

// MARK: - URL Matching Engine

/// Attempts to match a parsed URL against a list of route patterns.
/// Returns the first matching route value, or `nil` if none match.
@MainActor
public func matchRoute<R: Routable>(
    _ type: R.Type,
    segments: [String],
    query: [String: String],
    hash: String?
) -> R? {
    for pattern in R.patterns {
        switch pattern {
        case .exact(let path, let route):
            let patternSegments = URLParser.pathSegments(from: path)
            if segments == patternSegments {
                return route
            }

        case .param(let path, let factory):
            let patternSegments = URLParser.pathSegments(from: path)
            if let params = extractParams(patternSegments: patternSegments, urlSegments: segments) {
                let match = RouteMatch(params: params, query: query, hash: hash)
                return factory(match)
            }

        case .query(let path, let factory):
            let patternSegments = URLParser.pathSegments(from: path)
            if segments == patternSegments {
                let match = RouteMatch(params: [:], query: query, hash: hash)
                return factory(match)
            }

        case .nested(let prefix, let childType, let wrapper):
            let prefixSegments = URLParser.pathSegments(from: prefix)
            guard segments.count >= prefixSegments.count,
                  Array(segments.prefix(prefixSegments.count)) == prefixSegments
            else { continue }

            let remainingSegments = Array(segments.dropFirst(prefixSegments.count))
            if let childRoute = matchAnyRoutable(childType, segments: remainingSegments, query: query, hash: hash) {
                return wrapper(childRoute)
            }
        }
    }
    return nil
}

/// Type-erased helper for matching nested routable types.
@MainActor
private func matchAnyRoutable(
    _ type: any Routable.Type,
    segments: [String],
    query: [String: String],
    hash: String?
) -> (any Routable)? {
    func match<R: Routable>(_ type: R.Type) -> (any Routable)? {
        matchRoute(type, segments: segments, query: query, hash: hash)
    }
    return _openExistential(type, do: match)
}

/// Extracts path parameters by matching pattern segments against URL segments.
/// Pattern segments starting with `:` are treated as parameter names.
/// Returns `nil` if the segments don't match the pattern structure.
private func extractParams(
    patternSegments: [String],
    urlSegments: [String]
) -> [String: String]? {
    guard patternSegments.count == urlSegments.count else { return nil }

    var params: [String: String] = [:]
    for (pattern, actual) in zip(patternSegments, urlSegments) {
        if pattern.hasPrefix(":") {
            let paramName = String(pattern.dropFirst())
            params[paramName] = actual
        } else if pattern != actual {
            return nil
        }
    }
    return params
}
