// swift-tools-version:5.9
// Builds with just the Xcode Command Line Tools (no Xcode needed). See build.sh.
import PackageDescription

let package = Package(
    name: "TypoFix",
    platforms: [.macOS(.v14)],
    dependencies: [
        // Vendored copy of sindresorhus/KeyboardShortcuts (MIT) with its #Preview blocks removed,
        // because those need Xcode's preview macros.
        .package(path: "Vendor/KeyboardShortcuts"),
    ],
    targets: [
        .executableTarget(
            name: "TypoFix",
            dependencies: [.product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")]
        ),
    ]
)
