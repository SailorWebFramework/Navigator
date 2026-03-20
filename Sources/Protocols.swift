//
//  Protocols.swift
//  Navigator
//
//  Strongly typed routing protocols for Sailor web apps.
//

/// A type that can be used as a route (typically an enum).
/// Conforming types define URL patterns and can produce their canonical path.
@MainActor
public protocol Routable: Equatable {
    /// The patterns this route type matches against.
    static var patterns: [RoutePattern<Self>] { get }

    /// The canonical URL path for this route value (used for navigation).
    var path: String { get }
}

/// A type that encodes/decodes to/from URL query strings.
/// Requires `Codable` for serialization and `init()` for default fallback.
public protocol QueryParams: Codable, Equatable {
    init()
}

/// A type that maps to a hash fragment (typically a `String` `RawRepresentable` enum).
public protocol HashRoute: RawRepresentable, Equatable where RawValue == String {}
