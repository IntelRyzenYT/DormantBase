// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DormantBase",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "DormantBase",
            targets: ["DormantBase"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/evgenyneu/keychain-swift", .upToNextMajor(from: "24.0.0")),
        .package(url: "https://github.com/auth0/JWTDecode.swift", .upToNextMajor(from: "4.0.0")),
    ],
    targets: [
        .target(
            name: "DormantBase",
            dependencies: [
                .product(name: "KeychainSwift", package: "keychain-swift"),
                .product(name: "JWTDecode", package: "JWTDecode.swift")
            ]
        )
    ]
)