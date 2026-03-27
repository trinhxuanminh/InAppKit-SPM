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
            url: "https://github.com/trinhxuanminh/InAppKit-SPM/releases/download/1.0.0/InAppKit.xcframework.zip",
            checksum: "e1b5016eb5fcbe1205b4250494d559806d785f450f0d21823ed13826738a4823"
        )
    ]
)
