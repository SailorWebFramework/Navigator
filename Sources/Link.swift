//
//  Link.swift
//  Navigator
//
//  Navigation link components that render `<a>` tags with typed routing.
//

import Sailboat
import Sailor

/// A navigation link that renders an `<a>` tag pointing to a typed route.
/// On click, it calls `Navigator.go(to:)` instead of performing a full page navigation.
/// The `href` attribute is set for SEO and accessibility.
///
/// Usage:
/// ```swift
/// Link(to: AppRoute.about) {
///     Span("About Us")
/// }
/// ```
public struct Link<R: Routable>: Fragment {
    public var hash: String
    public var children: [any Page]

    public init(
        to route: R,
        @PageBuilder content: @escaping () -> any Fragment
    ) {
        let href = route.path
        let anchor = HTML.A(href: href) {
            content()
        }
        .onClick {
            Navigator.go(to: route)
        }

        self.hash = "link-\(href)"
        self.children = [anchor]
    }

    public init(
        to route: R,
        hash hashValue: String?,
        @PageBuilder content: @escaping () -> any Fragment
    ) {
        var href = route.path
        if let h = hashValue, !h.isEmpty {
            href += "#" + h
        }
        let anchor = HTML.A(href: href) {
            content()
        }
        .onClick {
            Navigator.go(to: route, hash: hashValue)
        }

        self.hash = "link-\(href)"
        self.children = [anchor]
    }

    public init<H: HashRoute>(
        to route: R,
        hash hashValue: H?,
        @PageBuilder content: @escaping () -> any Fragment
    ) {
        self.init(to: route, hash: hashValue?.rawValue, content: content)
    }
}

/// A hash-only navigation link that renders an `<a>` tag updating the hash fragment.
/// Stays on the current route and only changes the hash.
///
/// Usage:
/// ```swift
/// HashLink(to: DocsSection.api) {
///     Span("API Reference")
/// }
/// ```
public struct HashLink<H: HashRoute>: Fragment {
    public var hash: String
    public var children: [any Page]

    public init(
        to hashValue: H,
        @PageBuilder content: @escaping () -> any Fragment
    ) {
        let href = "#" + hashValue.rawValue
        let anchor = HTML.A(href: href) {
            content()
        }
        .onClick {
            Navigator.setHash(hashValue)
        }

        self.hash = "hashlink-\(hashValue.rawValue)"
        self.children = [anchor]
    }
}
