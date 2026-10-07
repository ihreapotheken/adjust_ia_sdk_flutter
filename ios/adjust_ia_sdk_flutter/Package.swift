// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "adjust_ia_sdk_flutter",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "adjust-ia-sdk-flutter", targets: ["adjust_ia_sdk_flutter"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(
            url: "https://github.com/adjust/ios_sdk",
            .upToNextMajor(from: "5.8.0")
        ),
    ],
    targets: [
        .target(
            name: "adjust_ia_sdk_flutter",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "AdjustSdk", package: "ios_sdk"),
            ]
        ),
    ]
)
