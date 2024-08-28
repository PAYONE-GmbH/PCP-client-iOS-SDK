// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PCPClient",
    platforms: [.macOS(.v12), .iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PCPClient",
            targets: ["PCPClient"]
        ),
        .library(
            name: "PCPClientBridge",
            targets: ["PCPClientBridge"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", exact: "0.56.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PCPClient",
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
        .target(
            name: "PCPClientBridge",
            dependencies: [.target(name: "PCPClient")]
        ),
        .testTarget(
            name: "PCPClientTests",
            dependencies: ["PCPClient"]
        ),
        .testTarget(
            name: "PCPClientBridgeTests",
            dependencies: ["PCPClientBridge"]
        )
    ]
)
