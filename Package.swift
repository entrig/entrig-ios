// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Entrig",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "Entrig",
            targets: ["Entrig"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Entrig",
            dependencies: [],
            path: "Sources/Entrig"
        )
    ]
)
