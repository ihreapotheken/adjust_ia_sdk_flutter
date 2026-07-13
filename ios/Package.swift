// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "adjust_ia_sdk_flutter",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(name: "adjust-ia-sdk-flutter", targets: ["adjust_ia_sdk_flutter"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/adjust/ios_sdk",
            .upToNextMajor(from: "5.7.0")
        ),
    ],
    targets: [
        .target(
            name: "adjust_ia_sdk_flutter",
            dependencies: [
                .product(name: "AdjustSdk", package: "ios_sdk"),
            ],
            path: "Classes"
        ),
    ]
)
