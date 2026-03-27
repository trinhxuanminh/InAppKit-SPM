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
            url: "https://github.com/trinhxuanminh/InAppKit-SPM/releases/download/1.1.2/InAppKit.xcframework.zip",
            checksum: "8c8dbc433488e288c5b5afbcca50304d760b46369f1691db32d40b235a49d8e6"
        )
    ]
)
