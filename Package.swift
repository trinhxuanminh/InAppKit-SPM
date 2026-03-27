// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InAppKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "InAppKit",
            targets: ["InAppKit"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .binaryTarget(
            name: "InAppKit",
            url: "https://github.com/trinhxuanminh/InAppKit-SPM/releases/download/1.1.1/InAppKit.xcframework.zip",
            checksum: "25a3b76ea93788005ea7bc239e8ce39e7fa1d73c5e03ab6d6cf5e6e18e24f717"
        )
    ]
)
