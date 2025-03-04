// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ImageDupes",
    platforms: [
           .macOS(.v11)
       ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "ImageDupes",
            targets: ["ImageDupes"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
       
        .executableTarget(
            name: "ImageDupes",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]

        ),
        .testTarget(
            name: "ImageDupesTests",
            dependencies: ["ImageDupes"]
        ),
    ]
)
