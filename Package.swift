// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Mockingbird",
    products: [
        .library(name: "Mockingbird", targets: ["Mockingbird"]),
        .library(name: "RxMockingbird", targets: ["RxMockingbird"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "5.0.0"))
    ],
    targets: [
        .target(
            name: "Mockingbird",
            path: "Sources/Mockingbird",
            exclude: ["Tests", "Sources/Supporting Files", "Examples", "Docs", "images"]),
        .target(
            name: "RxMockingbird",
            dependencies: ["Mockingbird", "RxSwift"],
            path: "Sources/RxMockingbird",
            exclude: ["Tests", "Sources/Supporting Files", "Examples", "Docs", "images"])
        .testTarget(
            name: "MockingbirdTests",
            dependencies: ["Mockingbird", "RxMockingbird"]),
    ]
)
