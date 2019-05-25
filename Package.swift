// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "Mockingbird",
    products: [
        .library(name: "Mockingbird", targets: ["Mockingbird"]),
        .library(name: "RxMockingbird", targets: ["RxMockingbird"]),
    ],
    dependencies: [
        .package(url: "https://github.com/antitypical/Result.git", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "4.0.0"))
    ],
    targets: [
        .target(
            name: "Mockingbird",
            dependencies: ["Result"],
            path: "Sources/Mockingbird",
            exclude: ["Tests", "Sources/Supporting Files", "Examples", "Docs", "images"]),
        .testTarget(
            name: "MockingbirdTests",
            dependencies: ["Mockingbird", "Result"]),
        .target(
            name: "RxMockingbird",
            dependencies: ["Mockingbird", "RxSwift"],
            path: "Sources/RxMockingbird",
            exclude: ["Tests", "Sources/Supporting Files", "Examples", "Docs", "images"])
    ]
)
