//
//  HashAnchor.swift
//  Navigator
//
//  Element modifier that sets an HTML `id` and scrolls into view when the hash matches.
//

import Sailboat
import Sailor
#if os(WASI)
import SailorWeb
import JavaScriptKit
#endif

extension Element {

    /// Mark this element as a hash anchor target using a typed `HashRoute` value.
    ///
    /// Sets the HTML `id` attribute to the route's `rawValue`.
    /// On appear, if `Navigator.hash` matches, calls `scrollIntoView()`.
    ///
    /// ```swift
    /// H2("API Reference")
    ///     .hashAnchor(DocsSection.api)
    /// ```
    @MainActor
    public func hashAnchor<H: HashRoute>(_ value: H) -> Self {
        hashAnchor(value.rawValue)
    }

    /// Mark this element as a hash anchor target using a raw string.
    ///
    /// Sets the HTML `id` attribute to the given string.
    /// On appear, if `Navigator.hash` matches, calls `scrollIntoView()`.
    ///
    /// ```swift
    /// H2("Some Section")
    ///     .hashAnchor("some-section")
    /// ```
    @MainActor
    public func hashAnchor(_ id: String) -> Self {
        self
            .attribute(ElementAttributeGroup(name: "id", value: { id }))
            .onAppear {
                #if os(WASI)
                if Navigator.hash == id {
                    // Scroll to this element using raw JS
                    let element = SailorWeb.JSNode.document.getElementById?(id)
                    _ = element?.object?.scrollIntoView?()
                }
                #endif
            }
    }
}
