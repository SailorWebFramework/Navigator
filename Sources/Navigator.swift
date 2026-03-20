//
//  Navigator.swift
//  Navigator
//
//  Central navigation controller — manages URL state and browser history.
//

import Sailboat

#if os(WASI)
import JavaScriptKit
#endif

/// Global configuration for Navigator.
public enum NavigatorConfig {
    /// Routing mode: `.path` (default) or `.hash`.
    @MainActor public static var mode: NavigatorMode = .path
}

/// Central navigation controller.
/// Manages the current URL, provides typed route access, and drives browser history.
@MainActor
public final class Navigator {

    // MARK: - Reactive URL State

    /// The current full URL string. Observed by Router to trigger re-renders.
    @Published public static var url: String = Navigator.readCurrentURL()

    /// The current hash fragment (without `#`), or `nil`.
    public static var hash: String? {
        let parsed = URLParser.parse(url, mode: NavigatorConfig.mode)
        return parsed.hash
    }

    /// Raw query parameter dictionary — read/write escape hatch.
    /// Prefixed with `__` to discourage casual use.
    public static var __rawQuery: [String: String] {
        get {
            let parsed = URLParser.parse(url, mode: NavigatorConfig.mode)
            return parsed.query
        }
        set {
            // Rebuild URL with new query params, keeping path and hash
            let parsed = URLParser.parse(url, mode: NavigatorConfig.mode)
            let pathStr = "/" + parsed.segments.joined(separator: "/")
            let queryStr = URLParser.encodeQueryString(newValue)
            var newURL = pathStr
            if !queryStr.isEmpty {
                newURL += "?" + queryStr
            }
            if let h = parsed.hash {
                newURL += "#" + h
            }
            performReplaceState(newURL)
        }
    }

    // MARK: - Typed Route Access

    /// Resolve the current URL against a specific `Routable` type.
    /// Returns the matched route or `nil` if no pattern matches.
    public static func current<R: Routable>(_ type: R.Type) -> R? {
        let parsed = URLParser.parse(url, mode: NavigatorConfig.mode)
        return matchRoute(type, segments: parsed.segments, query: parsed.query, hash: parsed.hash)
    }

    // MARK: - Navigation

    /// Push a new route onto the history stack.
    public static func go(to route: any Routable) {
        let newURL = route.path
        performPushState(newURL)
    }

    /// Push a new route with an optional hash fragment.
    public static func go(to route: any Routable, hash: String?) {
        var newURL = route.path
        if let h = hash, !h.isEmpty {
            newURL += "#" + h
        }
        performPushState(newURL)
    }

    /// Push a new route with a typed hash fragment.
    public static func go<H: HashRoute>(to route: any Routable, hash: H?) {
        go(to: route, hash: hash?.rawValue)
    }

    /// Replace the current history entry with a new route.
    public static func replace(_ route: any Routable) {
        let newURL = route.path
        performReplaceState(newURL)
    }

    /// Go back in browser history.
    public static func back() {
        #if os(WASI)
        let window = JSObject.global.window
        _ = window.history.object?.back?()
        #endif
    }

    /// Go forward in browser history.
    public static func forward() {
        #if os(WASI)
        let window = JSObject.global.window
        _ = window.history.object?.forward?()
        #endif
    }

    // MARK: - Hash Modification

    /// Set the hash fragment, keeping the current route.
    public static func setHash(_ value: String?) {
        let parsed = URLParser.parse(url, mode: NavigatorConfig.mode)
        let pathStr = "/" + parsed.segments.joined(separator: "/")
        let queryStr = URLParser.encodeQueryString(parsed.query)
        var newURL = pathStr
        if !queryStr.isEmpty {
            newURL += "?" + queryStr
        }
        if let h = value, !h.isEmpty {
            newURL += "#" + h
        }
        performReplaceState(newURL)
    }

    /// Set a typed hash fragment, keeping the current route.
    public static func setHash<H: HashRoute>(_ value: H?) {
        setHash(value?.rawValue)
    }

    // MARK: - Query Modification

    /// Mutate the current query params using a typed closure.
    /// Reads current query into `T`, applies the mutation, then updates the URL.
    public static func setQuery<T: QueryParams>(_ mutation: (inout T) -> Void) {
        let parsed = URLParser.parse(url, mode: NavigatorConfig.mode)
        let match = RouteMatch(params: [:], query: parsed.query, hash: parsed.hash)
        var params: T = match.decodeQuery()
        mutation(&params)

        let pathStr = "/" + parsed.segments.joined(separator: "/")
        let queryStr = URLParser.encodeQuery(params)
        var newURL = pathStr
        if !queryStr.isEmpty {
            newURL += "?" + queryStr
        }
        if let h = parsed.hash {
            newURL += "#" + h
        }
        performReplaceState(newURL)
    }

    /// Remove all query parameters from the current URL.
    public static func clearQuery() {
        let parsed = URLParser.parse(url, mode: NavigatorConfig.mode)
        let pathStr = "/" + parsed.segments.joined(separator: "/")
        var newURL = pathStr
        if let h = parsed.hash {
            newURL += "#" + h
        }
        performReplaceState(newURL)
    }

    // MARK: - Browser Integration

    /// Initialize browser event listeners. Call once at app startup.
    public static func start() {
        #if os(WASI)
        let window = JSObject.global.window

        // Listen for popstate (back/forward navigation)
        let popstateClosure = JSClosure { _ in
            Navigator.url = readCurrentURL()
            return .undefined
        }
        _ = window.addEventListener?("popstate", popstateClosure)

        // Listen for hashchange
        let hashchangeClosure = JSClosure { _ in
            Navigator.url = readCurrentURL()
            return .undefined
        }
        _ = window.addEventListener?("hashchange", hashchangeClosure)
        #endif
    }

    // MARK: - Internal

    /// Read the current URL from the browser, or return "/" for non-WASI.
    static func readCurrentURL() -> String {
        #if os(WASI)
        let window = JSObject.global.window
        return window.location.object?.href.string ?? "/"
        #else
        return "/"
        #endif
    }

    /// Push a new URL via history.pushState and update reactive state.
    private static func performPushState(_ path: String) {
        let fullURL: String
        switch NavigatorConfig.mode {
        case .path:
            fullURL = path
        case .hash:
            fullURL = "#" + path
        }

        #if os(WASI)
        let window = JSObject.global.window
        let history = window.history.object!
        let stateObject = JSObject.global.Object.function!.new()
        let title = JSValue.string("")
        _ = history.pushState?(stateObject, title, JSValue.string(fullURL))
        #endif

        url = readCurrentURL()
    }

    /// Replace the current URL without creating a history entry.
    /// Used by property wrappers (e.g. `@RouteQuery`, `@RouteHash`) to update the URL in-place.
    static func replaceURL(_ path: String) {
        performReplaceState(path)
    }

    /// Replace the current URL via history.replaceState and update reactive state.
    private static func performReplaceState(_ path: String) {
        let fullURL: String
        switch NavigatorConfig.mode {
        case .path:
            fullURL = path
        case .hash:
            fullURL = "#" + path
        }

        #if os(WASI)
        let window = JSObject.global.window
        let history = window.history.object!
        let stateObject = JSObject.global.Object.function!.new()
        let title = JSValue.string("")
        _ = history.replaceState?(stateObject, title, JSValue.string(fullURL))
        #endif

        url = readCurrentURL()
    }
}
