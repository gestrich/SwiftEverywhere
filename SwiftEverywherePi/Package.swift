// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftEverywherePi",
    platforms: [.macOS(.v15), .iOS(.v16)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/gestrich/SwiftyGPIO", branch: "bugfix/2024-12-pi-memory-address"),
        // .package(path: "../SwiftyGPIO")
        .package(url: "https://github.com/vapor/vapor.git", from: "4.99.3"),
        .package(path: "../SECommon")
    ],
    targets: [
        .executableTarget(
            name: "SEGPIOService",
            dependencies: [
                "SEGPIO",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftyGPIO", package: "SwiftyGPIO")
            ]
        ),
        .target(
            name: "SEGPIO",
            dependencies: [
                .product(name: "SwiftyGPIO", package: "SwiftyGPIO")
            ]
        ),
        .executableTarget(
            name: "SEServer",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                "SEGPIO",
                .product(name: "SECommon", package: "SECommon"),
                .product(name: "SwiftyGPIO", package: "SwiftyGPIO"),
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .testTarget(
            name: "SEServerTests",
            dependencies: [
                .target(name: "SEServer"),
                .product(name: "XCTVapor", package: "vapor"),
            ]
        )
    ]
)
