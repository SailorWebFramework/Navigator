//
//  Router.swift
//  Navigator
//
//  Fragment-based router component that evaluates Routable patterns
//  against the current URL and renders matched content.
//

import Sailboat
import Sailor

/// A router component that matches the current URL against a `Routable` type's patterns
/// and renders the corresponding content. Falls back to `notFound` if no pattern matches.
///
/// Usage:
/// ```swift
/// Router(for: AppRoute.self) { route in
///     switch route {
///     case .home: HomePage()
///     case .about: AboutPage()
///     }
/// } notFound: {
///     NotFoundPage()
/// }
/// ```
public struct Router<R: Routable>: Fragment {
    public var hash: String
    public var children: [any Page]

    public init(
        for routeType: R.Type,
        @PageBuilder content: @escaping (R) -> any Fragment,
        @PageBuilder notFound: @escaping () -> any Fragment
    ) {
        // Register dependency on Navigator.url so this re-renders on URL changes
        _ = Navigator.url

        let parsed = URLParser.parse(Navigator.url, mode: NavigatorConfig.mode)
        if let route = matchRoute(
            R.self,
            segments: parsed.segments,
            query: parsed.query,
            hash: parsed.hash
        ) {
            let fragment = content(route)
            self.children = fragment.children
            self.hash = "router-\(parsed.segments.joined(separator: "/"))"
        } else {
            let fragment = notFound()
            self.children = fragment.children
            self.hash = "router-notfound"
        }
    }
}
