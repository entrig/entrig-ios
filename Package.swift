// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "EntrigSDK",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "EntrigSDK",
            targets: ["EntrigSDK"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "EntrigSDK",
            dependencies: [],
            path: "Sources/EntrigSDK"
        )
    ]
)
