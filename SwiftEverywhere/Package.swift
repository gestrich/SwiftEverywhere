// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftEverywhere",
    platforms: [
        .iOS(.v16), .macOS(.v14)
    ],
    products: [
        .library(
            name: "SECommon",
            targets: ["SECommon"]),
        .executable(
            name: "SELambda",
            targets: ["SELambda"]
        ),
        .executable(
            name: "SEPi",
            targets: ["SEPi"]
        )
    ],
    
    dependencies: [
        .package(url: "https://github.com/soto-project/soto.git", "6.8.0"..<"7.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/gestrich/swift-server-utilities.git", "0.1.4"..<"0.2.0"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", "0.5.1"..<"1.0.0"),
        .package(url: "https://github.com/gestrich/SwiftyGPIO", branch: "bugfix/2024-12-pi-memory-address"),
        // .package(path: "../SwiftyGPIO")
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.99.3"),
    ],
    targets: [
        .target(
            name: "SECommon"),
        .executableTarget(
            name: "SELambda",
            dependencies: [
                .product(name: "AWSLambdaHelpers", package: "swift-server-utilities"),
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "NIOHelpers", package: "swift-server-utilities"),
                "SECommon",
                .product(name: "SotoDynamoDB", package: "soto"),
                .product(name: "SotoS3", package: "soto"),
                .product(name: "SotoSecretsManager", package: "soto"),
            ]
        ),
        .executableTarget(
            name: "SEPi",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                "SECommon",
                .product(name: "SwiftyGPIO", package: "SwiftyGPIO"),
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .testTarget(
            name: "SELambdaTests",
            dependencies: [
                .target(name: "SELambda")
            ]
        ),
        .testTarget(
            name: "SEPiTests",
            dependencies: [
                .target(name: "SEPi"),
                .product(name: "XCTVapor", package: "vapor"),
            ]
        )
    ]
)
