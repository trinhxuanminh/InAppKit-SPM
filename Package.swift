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
            url: "https://github.com/trinhxuanminh/InAppKit-SPM/releases/download/1.1.3/InAppKit.xcframework.zip",
            checksum: "a22df1d9b6ad1984c8b91c3e65ac014404e0b94c38fc50e5d0cf2db4b7a45880"
        )
    ]
)
