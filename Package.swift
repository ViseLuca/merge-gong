// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MergeGong",
    platforms: [.macOS(.v13)],
    targets: [
        // Providers, settings and merge tracking: no AppKit, covered by tests.
        .target(name: "MergeGongCore"),
        // The menu bar app.
        .executableTarget(name: "MergeGong", dependencies: ["MergeGongCore"]),
        .testTarget(name: "MergeGongCoreTests", dependencies: ["MergeGongCore"]),
    ],
    swiftLanguageModes: [.v5]
)
