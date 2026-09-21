// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Navigator",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Navigator",
            targets: ["Navigator"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/SailorWebFramework/Sailor", from: "0.2.0")
    ],
    targets: [
        .target(
            name: "Navigator",
            dependencies: [
                "Sailor"
            ]
        )
    ]
)
